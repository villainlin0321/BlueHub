[OPEN]

# iOS 真机网络请求异常调试记录

- sessionId: `ios-device-network`
- 日期: `2026-06-12`
- 问题现象: iOS 真机上网络请求报错，iOS 模拟器正常
- 预期行为: 真机与模拟器都能正常发起并完成网络请求
- 当前结论: 待采集运行时证据

## 已知信息

- 用户反馈: “真机上面请求会报错，但是模拟器没有这个问题”
- 当前影响面: iOS 真机网络能力，可能影响登录、首页、详情等所有接口

## 初始复现路径

1. 使用 iOS 真机安装并启动 App
2. 进入任意会触发接口请求的页面
3. 观察接口是否立即报错、超时或握手失败

## 待验证方向

- ATS / HTTP 明文限制
- 证书链或 HTTPS 握手问题
- 真机网络权限或域名解析差异
- 请求头 / 代理 / 本地地址配置差异

## 假设列表

| ID | 假设 | 概率 | 成本 | 预期信号 |
| --- | --- | --- | --- | --- |
| A | 真机命中的 `baseUrl` 或最终 URL 与模拟器不一致 | 高 | 低 | 日志里出现异常地址、局域网地址、localhost 或错误协议 |
| B | 真机失败发生在连接层或 TLS/证书层 | 高 | 低 | `DioExceptionType.connectionError`、握手失败、证书异常 |
| C | 请求成功到达服务端，但服务端返回异常状态码 | 中 | 低 | 日志出现 `statusCode`、`statusMessage` |
| D | 只有部分网络通道失败，例如 Void 请求、上传、SSE | 中 | 中 | 普通请求成功，但特定类型请求持续失败 |
| E | 真机与模拟器使用了不同的运行时环境配置 | 中 | 低 | 同一路径在日志中出现不同 `baseUrl` |

## 当前插桩点

- 文件: `lib/shared/network/api_client.dart`
- 点位 A: 请求发起前，记录 `method/path/baseUrl/resolvedUri`
- 点位 B: `DioException` 捕获时，记录 `type/status/errorText`
- 点位 C: 请求成功返回时，记录 `statusCode/statusMessage`
- 文件: `ios/Runner/AppDelegate.swift`
- 点位 B: 应用启动后自动执行一次原生 `URLSession` GET 探针，请求同一目标地址并记录成功/失败详情

## 当前证据

- 用户提供的真机运行时错误:
  - `DioException [connection error]`
  - `SocketException: Connection failed (OS Error: No route to host, errno = 65), address = 39.101.190.245, port = 8090`
- 用户补充:
  - iPhone 真机上的 Safari 可以直接打开 `http://39.101.190.245:8090`
- 代码静态配置:
  - `lib/shared/network/app_config.dart` 的 dev 默认地址为 `http://39.101.190.245:8090`
- 本机连通性验证:
  - `curl -I http://39.101.190.245:8090` 返回 `HTTP/1.1 500 Internal Server Error`
  - `nc -vz 39.101.190.245 8090` 连接成功

## 假设判定

| ID | 假设 | 状态 | 证据摘要 |
| --- | --- | --- | --- |
| A | 真机命中的 `baseUrl` 或最终 URL 与模拟器不一致 | ✅ 已确认关键目标地址 | 真机错误明确指向 `39.101.190.245:8090`，且 dev 配置就是该地址 |
| B | 真机失败发生在 App 网络栈的连接层，而不是纯粹物理断网 | ✅ 已确认 | Safari 可打开，但 Flutter App 报 `No route to host`，说明差异存在于应用网络栈/系统策略层 |
| C | 请求成功到达服务端，但服务端返回异常状态码 | ❌ 已排除 | 真机没有收到响应；服务端状态码只在本机 curl 时出现 |
| D | 只有部分网络通道失败，例如 Void 请求、上传、SSE | ⏳ 待定 | 当前证据显示基础 API 请求已失败，暂不优先 |
| E | 真机与模拟器使用了不同的运行时环境配置 | ❌ 基本排除 | 真机错误地址与代码默认 dev 地址一致，不像配置注入偏差 |

## 暂定根因

- 问题不在 Flutter 页面或接口封装逻辑。
- 也不是“整个手机都访问不到该地址”，因为 Safari 已可打开。
- 当前更可能是: Flutter/Dart 在 iOS 真机上的应用网络栈，与 Safari 对 `HTTP + 裸 IP + 8090` 的处理路径不同，导致 App 内连接失败。
