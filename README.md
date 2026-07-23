# bluehub_app

## API 文档

使用以下命令更新本地 API 文档：

```bash
curl "http://39.101.190.245:8090/v3/api-docs" -o ./docs/api/0510api.json
```

## 打包脚本

使用以下脚本执行发布打包：

```bash
./sh/build_all_release.sh
```

默认会先执行 APK 发布流程，再执行 IPA 发布流程。

仅执行 APK 发布：

```bash
./sh/build_all_release.sh -apk
```

仅执行 IPA 发布：

```bash
./sh/build_all_release.sh -ipa
```
