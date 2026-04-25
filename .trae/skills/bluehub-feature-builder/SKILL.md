---
name: "bluehub-feature-builder"
description: "基于 PRD+API+Figma 生成 BlueHub Flutter 功能骨架（Riverpod+go_router）。当要新增一个业务模块/页面流并落地到代码结构时调用。"
---

# BlueHub Feature Builder (Flutter)

## 目的

把“需求（docs/prd）+接口（docs/api）+Figma 设计图（最高优先级）”统一成可落地的 Flutter 功能骨架：

- 路由（go_router）
- 状态管理（Riverpod）
- 页面结构（widgets/screen）
- 数据层（models + repository）
- 基础错误/加载/空态

## 何时调用

- 新增一个 feature（例如：注册登录、申请创建、材料上传、进度追踪、消息、支付等）
- 需要把 Figma 页面流变成路由图 + 页面模板
- API 更新需要同步字段/状态到模型与 UI 展示

## 约束与约定

- 项目技术栈：Riverpod + go_router
- PRD 可能落后：页面与字段以 Figma 为准
- API 可能不全：缺失部分先用占位模型与 mock/接口 TODO 点，等待日期更新的 API 文档补齐

## 输出（建议一次性给齐）

1. 路由设计
   - 路由路径、参数、嵌套路由（如需要）、返回栈策略（go vs push）
2. 目录结构建议（按 feature）
   - `features/<feature>/` 下：`presentation/`、`application/`、`domain/`、`data/`（可按项目现状裁剪）
3. Riverpod 方案
   - `Provider/NotifierProvider` 选择理由
   - 状态对象与事件（加载、刷新、分页、提交）
4. 数据层方案
   - API DTO -> Domain Entity 映射（如需要）
   - Repository 接口 + 实现（含错误映射）
5. 验收点清单
   - 与 PRD 对齐、与 Figma 对齐、与 API 字段对齐

## 示例

**用户**：做“材料上传（OCR + 质量校验）”  
**你要做**：

- 先读 PRD/白板：上传步骤、质量校验点、低置信度提示、断点续传
- 再读 API：上传接口、文件字段、状态回调（若缺失则标注待补）
- 以 Figma 为准：页面布局与交互
- 输出：路由、页面模板、Riverpod 状态、repository 草案、验收点
