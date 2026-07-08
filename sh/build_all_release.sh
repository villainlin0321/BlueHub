#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PUB_CACHE_DIR="${PROJECT_ROOT}/.pub-cache"
PUBSPEC_FILE="${PROJECT_ROOT}/pubspec.yaml"
APK_OUTPUT_DIR="${PROJECT_ROOT}/build/app/outputs/flutter-apk"
APK_OUTPUT_FILE="${APK_OUTPUT_DIR}/app-release.apk"
IPA_OUTPUT_DIR="${PROJECT_ROOT}/build/ios/ipa"
APP_NAME_PREFIX="europepass"
COMMIT_MESSAGE="chore: bump build version"
IOS_EXPORT_METHOD="${IOS_EXPORT_METHOD:-ad-hoc}"
PGYER_API_KEY="06bd871b10060956dfad79248e0cd44c"
PGYER_INSTALL_TYPE="${PGYER_INSTALL_TYPE:-1}"
PGYER_PASSWORD="${PGYER_PASSWORD:-}"
PGYER_BUILD_DESCRIPTION="${PGYER_BUILD_DESCRIPTION:-}"
PGYER_UPDATE_DESCRIPTION="${PGYER_UPDATE_DESCRIPTION:-}"
PGYER_OVERSEA="${PGYER_OVERSEA:-2}"
WECOM_WEBHOOK_URL="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=b9fadafa-e50b-4acd-a15b-4bcddd47d349"

cd "${PROJECT_ROOT}"
mkdir -p "${PUB_CACHE_DIR}"
export PUB_CACHE="${PUB_CACHE_DIR}"
SUMMARY_DIR="$(mktemp -d "${PROJECT_ROOT}/.release-summary.XXXXXX")"
LAST_PGYER_INSTALL_URL=""
LAST_PGYER_QR_CODE_URL=""
LAST_WECOM_STATUS_MESSAGE=""
RUN_APK=1
RUN_IPA=1

fail() {
  echo "$1" >&2
  exit 1
}

cleanup() {
  [[ -d "${SUMMARY_DIR}" ]] && rm -rf "${SUMMARY_DIR}"
}

trap cleanup EXIT

require_file() {
  local file_path="$1"
  [[ -f "${file_path}" ]] || fail "File not found: ${file_path}"
}

require_command() {
  local command_name="$1"
  command -v "${command_name}" >/dev/null 2>&1 || fail "Command not found: ${command_name}"
}

print_usage() {
  cat <<EOF
Usage: $(basename "$0") [-apk | -ipa]

Options:
  -apk    Run APK release flow only.
  -ipa    Run IPA release flow only.

Without options, the script runs APK first, then IPA.
EOF
}

parse_args() {
  if [[ "$#" -gt 1 ]]; then
    print_usage
    fail "Only one optional argument is supported."
  fi

  if [[ "$#" -eq 0 ]]; then
    return 0
  fi

  case "$1" in
    -apk)
      RUN_IPA=0
      ;;
    -ipa)
      RUN_APK=0
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      print_usage
      fail "Unknown option: $1"
      ;;
  esac
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

reset_release_runtime() {
  LAST_PGYER_INSTALL_URL=""
  LAST_PGYER_QR_CODE_URL=""
  LAST_WECOM_STATUS_MESSAGE=""
}

write_release_summary_file() {
  local summary_file="$1"
  local artifact_label="$2"
  local artifact_path="$3"

  : > "${summary_file}"

  if [[ -n "${LAST_PGYER_INSTALL_URL}" ]]; then
    echo "PGYER install URL: ${LAST_PGYER_INSTALL_URL}" >> "${summary_file}"
  fi

  if [[ -n "${LAST_PGYER_QR_CODE_URL}" ]]; then
    echo "PGYER QR code URL: ${LAST_PGYER_QR_CODE_URL}" >> "${summary_file}"
  fi

  if [[ -n "${LAST_WECOM_STATUS_MESSAGE}" ]]; then
    echo "${LAST_WECOM_STATUS_MESSAGE}" >> "${summary_file}"
  fi

  echo "${artifact_label} generated: ${artifact_path}" >> "${summary_file}"
}

print_release_summary_file() {
  local summary_file="$1"

  [[ -s "${summary_file}" ]] || return 0
  cat "${summary_file}"
}

send_wecom_notification() {
  local display_name="$1"
  local build_version="$2"
  local install_url="$3"
  local qr_code_url="$4"
  local notification_time
  local content
  local payload
  local response
  local response_code
  local response_message

  if [[ -z "${WECOM_WEBHOOK_URL}" ]]; then
    LAST_WECOM_STATUS_MESSAGE="WECOM_WEBHOOK_URL not set, skip WeCom notification."
    echo "${LAST_WECOM_STATUS_MESSAGE}"
    return 0
  fi

  notification_time="$(date '+%F %T')"
  content=$'BlueHub 构建上传完成'
  content+=$'\n'"项目: ${APP_NAME_PREFIX}"
  content+=$'\n'"包类型: ${display_name}"
  content+=$'\n'"版本: ${build_version}"
  content+=$'\n'"时间: ${notification_time}"

  if [[ -n "${install_url}" ]]; then
    content+=$'\n'"安装链接: ${install_url}"
  fi

  if [[ -n "${qr_code_url}" ]]; then
    content+=$'\n'"二维码: ${qr_code_url}"
  fi

  payload="$(
    CONTENT="${content}" ruby -rjson -e '
      puts JSON.generate(
        msgtype: "text",
        text: { content: ENV.fetch("CONTENT") }
      )
    '
  )"

  response="$(
    curl \
      --silent \
      --show-error \
      --fail-with-body \
      --request POST \
      --header "Content-Type: application/json" \
      --data "${payload}" \
      "${WECOM_WEBHOOK_URL}"
  )" || {
    LAST_WECOM_STATUS_MESSAGE="Failed to send WeCom notification."
    echo "${LAST_WECOM_STATUS_MESSAGE}"
    return 0
  }

  response_code="$(extract_json_field_optional "${response}" errcode || true)"

  if [[ -n "${response_code}" && "${response_code}" != "0" ]]; then
    response_message="$(extract_json_field_optional "${response}" errmsg || true)"
    LAST_WECOM_STATUS_MESSAGE="WeCom notification failed: ${response_message:-${response}}"
    echo "${LAST_WECOM_STATUS_MESSAGE}"
    return 0
  fi

  LAST_WECOM_STATUS_MESSAGE="WeCom notification sent."
  echo "${LAST_WECOM_STATUS_MESSAGE}"
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

upload_to_pgyer() {
  local artifact_path="$1"
  local display_name="$2"
  local build_type="$3"
  local build_update_description="$4"
  local build_version="$5"
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

  LAST_PGYER_INSTALL_URL=""
  LAST_PGYER_QR_CODE_URL=""

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
    --data-urlencode "buildType=${build_type}"
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
      --form-string "key=${upload_key}" \
      --form-string "signature=${signature}" \
      --form-string "x-cos-security-token=${security_token}" \
      --form-string "x-cos-meta-file-name=$(basename "${artifact_path}")" \
      --form "file=@${artifact_path}"
  )"

  [[ "${upload_http_code}" == "204" ]] || fail "Failed to upload ${display_name} to PGYER, http code: ${upload_http_code}"

  build_key="${upload_key}"
  echo "${display_name} uploaded to PGYER storage, waiting for publishing..."

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
      LAST_PGYER_INSTALL_URL="${build_shortcut_url:+https://www.pgyer.com/${build_shortcut_url}}"
      LAST_PGYER_QR_CODE_URL="${build_qr_code_url}"

      echo "PGYER publish completed."
      if [[ -n "${LAST_PGYER_INSTALL_URL}" ]]; then
        echo "PGYER install URL: ${LAST_PGYER_INSTALL_URL}"
      fi
      if [[ -n "${LAST_PGYER_QR_CODE_URL}" ]]; then
        echo "PGYER QR code URL: ${LAST_PGYER_QR_CODE_URL}"
      fi
      send_wecom_notification \
        "${display_name}" \
        "${build_version}" \
        "${LAST_PGYER_INSTALL_URL}" \
        "${LAST_PGYER_QR_CODE_URL}"
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

upload_ipa_to_pgyer() {
  local ipa_path="$1"
  local build_update_description="$2"
  local build_version="$3"

  upload_to_pgyer "${ipa_path}" "IPA" "ipa" "${build_update_description}" "${build_version}"
}

upload_apk_to_pgyer() {
  local apk_path="$1"
  local build_update_description="$2"
  local build_version="$3"

  upload_to_pgyer "${apk_path}" "APK" "apk" "${build_update_description}" "${build_version}"
}

run_apk_release_flow() {
  local build_version="$1"
  local build_update_description="$2"
  local summary_file="$3"
  local renamed_apk

  reset_release_runtime
  build_apk

  renamed_apk="${APK_OUTPUT_DIR}/${APP_NAME_PREFIX}-${build_version}.apk"
  mv "${APK_OUTPUT_FILE}" "${renamed_apk}"

  upload_apk_to_pgyer "${renamed_apk}" "${build_update_description}" "${build_version}"
  write_release_summary_file "${summary_file}" "APK" "${renamed_apk}"
  print_release_summary_file "${summary_file}"
}

run_ipa_release_flow() {
  local build_version="$1"
  local build_update_description="$2"
  local summary_file="$3"
  local ipa_path
  local renamed_ipa

  reset_release_runtime
  build_ipa

  ipa_path="$(resolve_ipa_path)"
  renamed_ipa="${IPA_OUTPUT_DIR}/${APP_NAME_PREFIX}-${build_version}.ipa"
  mv "${ipa_path}" "${renamed_ipa}"

  upload_ipa_to_pgyer "${renamed_ipa}" "${build_update_description}" "${build_version}"
  write_release_summary_file "${summary_file}" "IPA" "${renamed_ipa}"
  print_release_summary_file "${summary_file}"
}

parse_args "$@"

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
release_update_description="${PGYER_UPDATE_DESCRIPTION:-Build ${next_version}}"
apk_summary_file="${SUMMARY_DIR}/apk.summary.log"
ipa_summary_file="${SUMMARY_DIR}/ipa.summary.log"
apk_flow_succeeded=0
ipa_flow_succeeded=0

sed -i '' "s/^version: .*/version: ${next_version}/" "${PUBSPEC_FILE}"

echo "Version updated: ${current_version} -> ${next_version}"

git add pubspec.yaml sh/build_all_release.sh
git commit -m "${COMMIT_MESSAGE}"
git push

if [[ "${RUN_APK}" -eq 1 ]]; then
  if ( run_apk_release_flow "${next_version}" "${release_update_description}" "${apk_summary_file}" ); then
    apk_flow_succeeded=1
  else
    if [[ "${RUN_IPA}" -eq 1 ]]; then
      echo "APK release flow failed, continue with IPA release flow." >&2
    else
      echo "APK release flow failed." >&2
    fi
  fi
fi

if [[ "${RUN_IPA}" -eq 1 ]]; then
  if ( run_ipa_release_flow "${next_version}" "${release_update_description}" "${ipa_summary_file}" ); then
    ipa_flow_succeeded=1
  else
    echo "IPA release flow failed." >&2
  fi
fi

if [[ "${apk_flow_succeeded}" -eq 1 || "${ipa_flow_succeeded}" -eq 1 ]]; then
  echo "Release flows finished. Final summary:"
  print_release_summary_file "${apk_summary_file}"
  print_release_summary_file "${ipa_summary_file}"
fi

if [[ "${RUN_APK}" -eq 1 && "${RUN_IPA}" -eq 1 ]]; then
  [[ "${ipa_flow_succeeded}" -eq 1 ]] || fail "IPA release flow failed."
elif [[ "${RUN_APK}" -eq 1 ]]; then
  [[ "${apk_flow_succeeded}" -eq 1 ]] || fail "APK release flow failed."
elif [[ "${RUN_IPA}" -eq 1 ]]; then
  [[ "${ipa_flow_succeeded}" -eq 1 ]] || fail "IPA release flow failed."
fi
