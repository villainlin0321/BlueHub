#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-"$SCRIPT_DIR/../BlueHub2"}"
API_FILE="${2:-}"

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Repo not found: $REPO_ROOT" >&2
  exit 1
fi

if [[ -z "$API_FILE" ]]; then
  API_FILE="$(python3 - "$REPO_ROOT" <<'PY'
import re
import sys
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
api_dir = repo_root / "docs" / "api"
files = sorted(api_dir.glob("*api.json"))
if not files:
    raise SystemExit("")

def sort_key(path: Path) -> tuple[int, str]:
    match = re.search(r"(\d+)", path.stem)
    return (int(match.group(1)) if match else -1, path.name)

print(max(files, key=sort_key))
PY
)"
fi

if [[ -z "$API_FILE" || ! -f "$API_FILE" ]]; then
  echo "API file not found: $API_FILE" >&2
  exit 1
fi

python3 - "$REPO_ROOT" "$API_FILE" <<'PY'
import json
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
api_file = Path(sys.argv[2]).resolve()
service_dir = repo_root / "lib" / "shared" / "network" / "services"

API_METHODS = {"get", "post", "put", "delete", "patch"}
SERVICE_PATTERN = re.compile(
    r"_apiClient\.(get|post|put|delete|getVoid|postVoid|putVoid|deleteVoid)(?:<[^)]*>)?\(\s*['\"]([^'\"]+)['\"]",
    re.S,
)
METHOD_MAP = {
    "get": "GET",
    "post": "POST",
    "put": "PUT",
    "delete": "DELETE",
    "getVoid": "GET",
    "postVoid": "POST",
    "putVoid": "PUT",
    "deleteVoid": "DELETE",
}


def normalize_path(path: str) -> str:
    path = re.sub(r"\$\{([^}]+)\}", r"{\1}", path)
    path = re.sub(r"\$([A-Za-z_][A-Za-z0-9_]*)", r"{\1}", path)
    return path


def parse_sse_calls(text: str) -> set[tuple[str, str]]:
    operations: set[tuple[str, str]] = set()
    anchor = "_sseClient.connect("
    search_from = 0
    while True:
        start = text.find(anchor, search_from)
        if start == -1:
            break

        paren_start = text.find("(", start)
        if paren_start == -1:
            break

        depth = 0
        end = paren_start
        in_string = False
        string_char = ""
        while end < len(text):
            char = text[end]
            if in_string:
                if char == "\\":
                    end += 2
                    continue
                if char == string_char:
                    in_string = False
                end += 1
                continue
            if char in {"'", '"'}:
                in_string = True
                string_char = char
                end += 1
                continue
            if char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth == 0:
                    end += 1
                    break
            end += 1

        invocation = text[start:end]
        path_match = re.search(r"_sseClient\.connect\(\s*['\"]([^'\"]+)['\"]", invocation)
        if path_match:
          method_match = re.search(r"method\s*:\s*['\"]([A-Za-z]+)['\"]", invocation)
          method = (method_match.group(1).upper() if method_match else "GET")
          operations.add((method, normalize_path(path_match.group(1))))
        search_from = end
    return operations


def parse_service_content(text: str) -> set[tuple[str, str]]:
    operations: set[tuple[str, str]] = set()
    for match in SERVICE_PATTERN.finditer(text):
        method = METHOD_MAP[match.group(1)]
        path = normalize_path(match.group(2))
        operations.add((method, path))
    operations.update(parse_sse_calls(text))
    return operations


def parse_service_files() -> tuple[dict[str, set[tuple[str, str]]], set[tuple[str, str]]]:
    file_ops: dict[str, set[tuple[str, str]]] = {}
    all_ops: set[tuple[str, str]] = set()
    for file_path in sorted(service_dir.glob("*.dart")):
        ops = parse_service_content(file_path.read_text())
        rel_path = file_path.relative_to(repo_root).as_posix()
        file_ops[rel_path] = ops
        all_ops.update(ops)
    return file_ops, all_ops


def parse_api_ops() -> list[tuple[str, str]]:
    document = json.loads(api_file.read_text())
    result: list[tuple[str, str]] = []
    for path, item in document["paths"].items():
        for method in item:
            if method.lower() in API_METHODS:
                result.append((method.upper(), path))
    return sorted(result)


def run_git(*args: str) -> str:
    completed = subprocess.run(
        ["git", "-C", str(repo_root), *args],
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        return ""
    return completed.stdout


def list_modified_service_files() -> list[str]:
    output = run_git("status", "--porcelain", "--", "lib/shared/network/services")
    files: list[str] = []
    for line in output.splitlines():
        if len(line) < 4:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        if path.endswith(".dart"):
            files.append(path)
    return sorted(set(files))


def load_head_ops(rel_path: str) -> set[tuple[str, str]]:
    content = run_git("show", f"HEAD:{rel_path}")
    if not content:
        return set()
    return parse_service_content(content)


api_ops = parse_api_ops()
file_ops, service_ops = parse_service_files()
api_op_set = set(api_ops)
missing_ops = sorted(api_op_set - service_ops)
extra_ops = sorted(service_ops - api_op_set)

print("== BlueHub2 API Service Check ==")
print(f"repo: {repo_root}")
print(f"api : {api_file}")
print(f"api operations     : {len(api_ops)}")
print(f"service operations : {len(service_ops)}")
print(f"missing operations : {len(missing_ops)}")
print(f"extra operations   : {len(extra_ops)}")

print("\n[Coverage By Service]")
for rel_path, ops in sorted(file_ops.items()):
    print(f"- {rel_path}: {len(ops)}")

print("\n[Missing Operations]")
if missing_ops:
    for method, path in missing_ops:
        print(f"- {method:6} {path}")
else:
    print("- none")

print("\n[Extra Operations Not In API Doc]")
if extra_ops:
    for method, path in extra_ops:
        print(f"- {method:6} {path}")
else:
    print("- none")

modified_files = list_modified_service_files()
print("\n[Modified Service Files]")
if modified_files:
    for rel_path in modified_files:
        print(f"- {rel_path}")
else:
    print("- none")

print("\n[Modified Interface Mappings vs HEAD]")
if not modified_files:
    print("- none")
else:
    for rel_path in modified_files:
        current_ops = file_ops.get(rel_path, set())
        head_ops = load_head_ops(rel_path)
        added_ops = sorted(current_ops - head_ops)
        removed_ops = sorted(head_ops - current_ops)
        unchanged_count = len(current_ops & head_ops)
        print(f"- {rel_path}")
        print(f"  unchanged: {unchanged_count}")
        if added_ops:
            print("  added:")
            for method, path in added_ops:
                print(f"    + {method:6} {path}")
        if removed_ops:
            print("  removed:")
            for method, path in removed_ops:
                print(f"    - {method:6} {path}")
        if not added_ops and not removed_ops:
            print("  added: none")
            print("  removed: none")
PY
