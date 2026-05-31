#!/usr/bin/env bash
set -euo pipefail

IOS_SPECS=(
  "Icon-App-20x20@1x.png:20"
  "Icon-App-20x20@2x.png:40"
  "Icon-App-20x20@3x.png:60"
  "Icon-App-29x29@1x.png:29"
  "Icon-App-29x29@2x.png:58"
  "Icon-App-29x29@3x.png:87"
  "Icon-App-40x40@1x.png:40"
  "Icon-App-40x40@2x.png:80"
  "Icon-App-40x40@3x.png:120"
  "Icon-App-60x60@2x.png:120"
  "Icon-App-60x60@3x.png:180"
  "Icon-App-76x76@1x.png:76"
  "Icon-App-76x76@2x.png:152"
  "Icon-App-83.5x83.5@2x.png:167"
  "Icon-App-1024x1024@1x.png:1024"
)

generate_ios_icons() {
  local src="$1"
  local out_dir="$2"

  local tmp_png
  tmp_png="$(mktemp -t bluehub_icon).png"

  sips -s format png "$src" --out "$tmp_png" >/dev/null

  for spec in "${IOS_SPECS[@]}"; do
    local name="${spec%%:*}"
    local size="${spec##*:}"
    sips -z "$size" "$size" "$tmp_png" --out "$out_dir/$name" >/dev/null
  done

  rm -f "$tmp_png"
}

generate_android_icons() {
  local src="$1"
  local out_base="$2"
  local out_name="$3"

  local tmp_png
  tmp_png="$(mktemp -t bluehub_icon).png"

  sips -s format png "$src" --out "$tmp_png" >/dev/null

  local android_specs=(
    "mipmap-mdpi:48"
    "mipmap-hdpi:72"
    "mipmap-xhdpi:96"
    "mipmap-xxhdpi:144"
    "mipmap-xxxhdpi:192"
  )

  for spec in "${android_specs[@]}"; do
    local dir="${spec%%:*}"
    local size="${spec##*:}"
    mkdir -p "$out_base/$dir"
    sips -z "$size" "$size" "$tmp_png" --out "$out_base/$dir/$out_name" >/dev/null
  done

  rm -f "$tmp_png"
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

generate_ios_icons "WechatIMG460.jpg" "ios/Runner/Assets.xcassets/AppIcon.appiconset"
generate_ios_icons "WechatIMG461.jpg" "ios/Runner/Assets.xcassets/AppIconZh.appiconset"

generate_android_icons "WechatIMG460.jpg" "android/app/src/main/res" "ic_launcher.png"
generate_android_icons "WechatIMG461.jpg" "android/app/src/main/res" "ic_launcher_zh.png"

echo "done"
