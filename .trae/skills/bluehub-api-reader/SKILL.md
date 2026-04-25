---
name: "bluehub-api-reader"
description: "读取并总结 BlueHub API 文档（docs/api）。当要对接接口、生成模型/请求封装、梳理状态码与字段含义时调用；API 可能不全，优先选最新日期文件。"
---

# BlueHub API Reader

## 目的

从 `/Users/xinren/BlueHub/docs/api` 的 API JSON 文档中提取可直接用于开发的接口清单、请求/响应结构、状态码、字段约束，并生成 Flutter（Riverpod + go_router）常用的网络层落地建议。

## 何时调用

- 接入后端接口：登录/列表/详情/提交/支付/进度等
- 需要生成数据模型（DTO/VO）、枚举、解析逻辑、错误处理策略
- API 更新了（文件名带日期），需要对比差异并同步到代码

## 输入来源与优先级

1. `docs/api` 中“日期最新”的 JSON（例如 `0421api.json`；后续会按日期追加）
2. 若 API 缺失字段/接口：以 Figma 为准定义 UI 字段占位，并在实现中显式标注待补接口点
3. 若 PRD 与 API 冲突：字段/状态以 API 为准；流程/交互以 Figma 为准

## 工作步骤（建议输出格式）

1. 选取最新 API 文件
   - 优先按文件名日期排序；若无法解析日期则按修改时间排序
2. 输出接口目录（按业务域分组）
   - path + method + 简述 + 鉴权方式（如有）
3. 为每个接口输出：
   - 请求：query/path/body 字段、必填/可选、类型、约束
   - 响应：data 结构、分页字段、枚举值、错误码
   - 端侧处理：加载/空态/错误态、重试、幂等与去重策略
4. 输出 Flutter 落地建议：
   - Model 命名建议（DTO/Entity）
   - Repository 接口设计（面向业务用例）
   - Riverpod Provider 组织方式（按 feature 分组）

## 示例

**用户**：把“案件进度”接口接到 App  
**你要做**：

- 从最新 API JSON 中找到相关 endpoint
- 输出：字段表、状态枚举、分页/轮询策略、错误码处理
- 给出：Riverpod provider + repository 的接口草案
