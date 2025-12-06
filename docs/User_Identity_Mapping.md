# 用户标识与数据映射说明（Mock API 与 Supabase）

本文件明确用户名（`username`）与内部用户 ID（`id`）的关系，以及在 Supabase `word_cards` 表中 `user_id` 的使用方式，避免后续排查数据时出现“看不到属于自己的数据”的问题。

## 术语
- `username`：用户登录名，例如 `123456`。
- `id`（内部用户 ID）：后端生成的用户唯一标识，在 Mock API 中形如 `u_1`、`u_2`，在正式后端（如 Supabase Auth）通常为 UUID。
- `word_cards.user_id`：单词卡归属的用户 ID（内部 ID）。公开共享内容用 `NULL`。

## Mock API 的生成规则
- 注册接口 `/auth/register` 会为新用户分配递增的内部 ID：第一个注册用户为 `u_1`，第二个为 `u_2`，以此类推。
- 登录接口 `/auth/login` 支持用用户名或邮箱登录，返回的 `user.id` 为上述内部 ID。

示例：
```
POST /auth/register
{"email":"test123456@example.com","username":"123456","password":"Pass12345"}

响应：
{"token":"mock-token-123456","user":{"id":"u_1","email":"test123456@example.com","username":"123456"}}
```

由此确认：当前映射关系为 `username=123456 -> id=u_1`。

查询当前所有用户（不包含密码）：
```
GET /users
{"users":[{"id":"u_1","email":"test123456@example.com","username":"123456"}]}
```

## Supabase `word_cards` 表的归属字段
- `user_id` 存储的是“内部用户 ID”，而不是用户名。
- 面向所有用户公开的数据，其 `user_id` 应为 `NULL`（可视为共享库）。

因此：
- 如果前端用 `username`（例如 `123456`）去过滤 `word_cards.user_id`，将无法匹配到 `u_1` 归属的数据。
- 应当使用后端返回的 `user.id`（例如 `u_1` 或 UUID）去过滤 `word_cards.user_id`。

## 前端集成注意事项
- 当前 `AuthProvider.userId` 返回的是 `currentUser.username`（用户名）。这在与 Supabase 交互时会导致过滤错位。
- 建议改为使用 `currentUser.id` 作为用户标识参与写入与过滤，以与 `word_cards.user_id` 保持一致。
- 兼容策略（过渡期）：读取时可同时包含共享（`user_id IS NULL`）与当前用户内部 ID 的数据。

## 可视化/验证操作
- 验证 Mock 用户身份：`GET /auth/me`（携带 `Authorization: Bearer mock-token-<username>`）可返回 `{"id":"u_1","username":"123456"}`。
- 验证 Supabase 归属数据：在 `word_cards` 中查询 `user_id='u_1'` 可看到属于用户 `123456` 的数据；查询 `user_id IS NULL` 可看到共享数据。

## 数据迁移建议（如需临时对齐用户名）
- 不推荐将 `word_cards.user_id` 改为用户名（会与正式后端的 UUID 设计冲突）。
- 如需临时验证显示效果，可将部分数据的 `user_id` 批量更新为当前用户的内部 ID（例如 `u_1`）。

## 公开可见性的补充
- 导入共享内容时，请将 `user_id` 设为 `NULL`，避免将公共库绑定到某个具体用户。

---
维护人：EWC 项目组
最后更新：2025-11-11