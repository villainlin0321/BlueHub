#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PUBSPEC_FILE="${PROJECT_ROOT}/pubspec.yaml"
APK_OUTPUT_DIR="${PROJECT_ROOT}/build/app/outputs/flutter-apk"
APK_OUTPUT_FILE="${APK_OUTPUT_DIR}/app-release.apk"
IPA_OUTPUT_DIR="${PROJECT_ROOT}/build/ios/ipa"
APP_NAME_PREFIX="europepass"
COMMIT_MESSAGE="chore: bump build version"
IOS_EXPORT_METHOD="${IOS_EXPORT_METHOD:-ad-hoc}"
PGYER_API_KEY="${PGYER_API_KEY:-}"
PGYER_INSTALL_TYPE="${PGYER_INSTALL_TYPE:-1}"
PGYER_PASSWORD="${PGYER_PASSWORD:-}"
PGYER_BUILD_DESCRIPTION="${PGYER_BUILD_DESCRIPTION:-}"
PGYER_UPDATE_DESCRIPTION="${PGYER_UPDATE_DESCRIPTION:-}"
PGYER_OVERSEA="${PGYER_OVERSEA:-2}"

cd "${PROJECT_ROOT}"

fail() {
  echo "$1" >&2
  exit 1
}

require_file() {
  local file_path="$1"
  [[ -f "${file_path}" ]] || fail "File not found: ${file_path}"
}

require_command() {
  local command_name="$1"
  command -v "${command_name}" >/dev/null 2>&1 || fail "Command not found: ${command_name}"
}

extract_json_field() {
  local json_payload="$1"
  shift

  ruby -rjson -e '
    data = JSON.parse(STDIN.read)
    ARGV.each { |key| data = data.fetch(key) }
    puts data
  ' "$@" <<< "${json_payload}"
}

extract_json_field_optional() {
  local json_payload="$1"
  shift

  ruby -rjson -e '
    begin
      data = JSON.parse(STDIN.read)
      ARGV.each { |key| data = data.fetch(key) }
      puts data
    rescue JSON::ParserError, KeyError, NoMethodError
      exit 1
    end
  ' "$@" <<< "${json_payload}"
}

resolve_ipa_path() {
  local ipa_count
  ipa_count="$(find "${IPA_OUTPUT_DIR}" -maxdepth 1 -name '*.ipa' | wc -l | tr -d ' ')"

  [[ "${ipa_count}" -gt 0 ]] || fail "Release IPA not found in ${IPA_OUTPUT_DIR}"

  ls -t "${IPA_OUTPUT_DIR}"/*.ipa 2>/dev/null | head -n 1
}

build_apk() {
  flutter build apk --release
  [[ -f "${APK_OUTPUT_FILE}" ]] || fail "Release APK not found: ${APK_OUTPUT_FILE}"
}

build_ipa() {
  flutter build ipa --release --export-method "${IOS_EXPORT_METHOD}"
}

upload_ipa_to_pgyer() {
  local ipa_path="$1"
  local build_update_description="$2"
  local token_response
  local token_code
  local upload_endpoint
  local upload_key
  local signature
  local security_token
  local upload_http_code
  local build_info_response
  local build_info_code
  local build_info_message
  local build_shortcut_url
  local build_qr_code_url
  local build_key
  local attempt
  local curl_args=()

  if [[ -z "${PGYER_API_KEY}" ]]; then
    echo "PGYER_API_KEY not set, skip PGYER upload."
    return 0
  fi

  if [[ "${PGYER_INSTALL_TYPE}" == "2" && -z "${PGYER_PASSWORD}" ]]; then
    fail "PGYER_INSTALL_TYPE=2 requires PGYER_PASSWORD."
  fi

  curl_args=(
    --silent
    --show-error
    --fail-with-body
    --request POST
    "https://api.pgyer.com/apiv2/app/getCOSToken"
    --data-urlencode "_api_key=${PGYER_API_KEY}"
    --data-urlencode "buildType=ipa"
    --data-urlencode "buildInstallType=${PGYER_INSTALL_TYPE}"
    --data-urlencode "buildUpdateDescription=${build_update_description}"
    --data-urlencode "oversea=${PGYER_OVERSEA}"
  )

  if [[ -n "${PGYER_BUILD_DESCRIPTION}" ]]; then
    curl_args+=(--data-urlencode "buildDescription=${PGYER_BUILD_DESCRIPTION}")
  fi

  if [[ -n "${PGYER_PASSWORD}" ]]; then
    curl_args+=(--data-urlencode "buildPassword=${PGYER_PASSWORD}")
  fi

  token_response="$(curl "${curl_args[@]}")"
  token_code="$(extract_json_field "${token_response}" code)"
  [[ "${token_code}" == "0" ]] || fail "Failed to get PGYER upload token: ${token_response}"

  upload_endpoint="$(extract_json_field "${token_response}" data endpoint)"
  upload_key="$(extract_json_field "${token_response}" data key)"
  signature="$(extract_json_field "${token_response}" data params signature)"
  security_token="$(extract_json_field "${token_response}" data params x-cos-security-token)"

  upload_http_code="$(
    curl \
      --silent \
      --show-error \
      --output /dev/null \
      --write-out "%{http_code}" \
      --request POST \
      "${upload_endpoint}" \
      --form "key=${upload_key}" \
      --form "signature=${signature}" \
      --form "x-cos-security-token=${security_token}" \
      --form "x-cos-meta-file-name=$(basename "${ipa_path}")" \
      --form "file=@${ipa_path}"
  )"

  [[ "${upload_http_code}" == "204" ]] || fail "Failed to upload IPA to PGYER, http code: ${upload_http_code}"

  build_key="${upload_key}"
  echo "IPA uploaded to PGYER storage, waiting for publishing..."

  for attempt in {1..20}; do
    build_info_response="$(
      curl \
        --silent \
        --show-error \
        --fail-with-body \
        --get \
        "https://api.pgyer.com/apiv2/app/buildInfo" \
        --data-urlencode "_api_key=${PGYER_API_KEY}" \
        --data-urlencode "buildKey=${build_key}"
    )"

    build_info_code="$(extract_json_field_optional "${build_info_response}" code || true)"

    if [[ -z "${build_info_code}" || "${build_info_code}" == "0" ]]; then
      build_shortcut_url="$(extract_json_field_optional "${build_info_response}" data buildShortcutUrl || extract_json_field_optional "${build_info_response}" buildShortcutUrl || true)"
      build_qr_code_url="$(extract_json_field_optional "${build_info_response}" data buildQRCodeURL || extract_json_field_optional "${build_info_response}" buildQRCodeURL || true)"

      echo "PGYER publish completed."
      if [[ -n "${build_shortcut_url}" ]]; then
        echo "PGYER install URL: https://www.pgyer.com/${build_shortcut_url}"
      fi
      if [[ -n "${build_qr_code_url}" ]]; then
        echo "PGYER QR code URL: ${build_qr_code_url}"
      fi
      return 0
    fi

    if [[ "${build_info_code}" == "1246" || "${build_info_code}" == "1247" ]]; then
      echo "PGYER publishing in progress (${attempt}/20)..."
      sleep 3
      continue
    fi

    build_info_message="$(extract_json_field_optional "${build_info_response}" message || true)"
    fail "PGYER publish failed: ${build_info_message:-${build_info_response}}"
  done

  echo "PGYER upload completed, but publishing is still in progress. Check it later in PGYER console."
}

require_file "${PUBSPEC_FILE}"
require_command flutter
require_command git
require_command curl
require_command ruby

current_version_line="$(grep '^version:' "${PUBSPEC_FILE}")"
[[ -n "${current_version_line}" ]] || fail "Failed to find version line in ${PUBSPEC_FILE}"

current_version="${current_version_line#version: }"

if [[ ! "${current_version}" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$ ]]; then
  fail "Unsupported version format: ${current_version}"
fi

build_name="${BASH_REMATCH[1]}"
build_number="${BASH_REMATCH[2]}"
next_build_number=$((build_number + 1))
next_version="${build_name}+${next_build_number}"

sed -i '' "s/^version: .*/version: ${next_version}/" "${PUBSPEC_FILE}"

echo "Version updated: ${current_version} -> ${next_version}"

build_apk
build_ipa

renamed_apk="${APK_OUTPUT_DIR}/${APP_NAME_PREFIX}-${next_version}.apk"
mv "${APK_OUTPUT_FILE}" "${renamed_apk}"

ipa_path="$(resolve_ipa_path)"
renamed_ipa="${IPA_OUTPUT_DIR}/${APP_NAME_PREFIX}-${next_version}.ipa"
mv "${ipa_path}" "${renamed_ipa}"

git add pubspec.yaml
git commit -m "${COMMIT_MESSAGE}"
git push

upload_ipa_to_pgyer "${renamed_ipa}" "${PGYER_UPDATE_DESCRIPTION:-Build ${next_version}}"

echo "APK generated: ${renamed_apk}"
echo "IPA generated: ${renamed_ipa}"
