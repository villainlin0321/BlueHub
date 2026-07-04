// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "file_picker",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "file-picker", targets: ["file_picker"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "file_picker",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            cSettings: [
                .headerSearchPath("include/file_picker"),
                // 项目当前仅使用文件选择能力，避免引入媒体依赖链与 image_cropper 的裁剪库冲突。
                .define("PICKER_AUDIO"),
                .define("PICKER_DOCUMENT")
            ]
        )
    ]
)
