#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PUBSPEC_FILE="${PROJECT_ROOT}/pubspec.yaml"
OUTPUT_DIR="${PROJECT_ROOT}/build/app/outputs/flutter-apk"
OUTPUT_APK="${OUTPUT_DIR}/app-release.apk"
COMMIT_MESSAGE="chore: bump build version"
APP_NAME_PREFIX="europepass"

cd "${PROJECT_ROOT}"

if [[ ! -f "${PUBSPEC_FILE}" ]]; then
  echo "pubspec.yaml not found: ${PUBSPEC_FILE}" >&2
  exit 1
fi

current_version_line="$(grep '^version:' "${PUBSPEC_FILE}")"

if [[ -z "${current_version_line}" ]]; then
  echo "Failed to find version line in ${PUBSPEC_FILE}" >&2
  exit 1
fi

current_version="${current_version_line#version: }"

if [[ ! "${current_version}" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$ ]]; then
  echo "Unsupported version format: ${current_version}" >&2
  exit 1
fi

build_name="${BASH_REMATCH[1]}"
build_number="${BASH_REMATCH[2]}"
next_build_number=$((build_number + 1))
next_version="${build_name}+${next_build_number}"

sed -i '' "s/^version: .*/version: ${next_version}/" "${PUBSPEC_FILE}"

echo "Version updated: ${current_version} -> ${next_version}"

flutter build apk --release

if [[ ! -f "${OUTPUT_APK}" ]]; then
  echo "Release APK not found: ${OUTPUT_APK}" >&2
  exit 1
fi

renamed_apk="${OUTPUT_DIR}/${APP_NAME_PREFIX}-${next_version}.apk"
mv "${OUTPUT_APK}" "${renamed_apk}"

git add pubspec.yaml
git commit -m "${COMMIT_MESSAGE}"
git push

echo "APK generated: ${renamed_apk}"
