# Phase 3 验证与验收 Checklist

## 验收目标映射
- G1 注册（邮箱+用户名唯一校验）
- G2 登录（用户名，大小写不敏感）
- G3 生成 JWT Token 并在后续请求携带
- G4 Token 安全存储与自动登录（FlutterSecureStorage + Splash）
- G5 登出清除登录状态与本地数据
- G6 用户数据隔离（词卡/标签按 `user_id` 区分）
- G7 密码加密存储，HTTPS 传输
- G8 错误提示友好，输入校验完善

## 验收项（开发侧自查）
- [ ] 注册接口已上线，返回 `{ token, user }`
- [ ] 登录接口返回 Token，错误凭证返回明确错误码
- [ ] `/auth/verify-token` 中间件正常（200 有效，401 过期/伪造）
- [ ] Flutter 登录/注册 UI 可用，输入校验与 loading 状态正确
- [ ] 自动登录：重启 App 进入首页（SplashScreen + AuthProvider.bootstrap）
- [ ] 登出清除 SecureStorage 中 Token，回到登录页
- [ ] 数据隔离：A 用户数据在 B 账号中不可见
- [ ] 错误提示准确（重复邮箱/用户名、弱密码、无效邮箱、用户不存在、密码错误）
- [ ] 加密存储验证通过（后端 `password_hash=bcrypt`），接口走 HTTPS
- [ ] 稳定性：连续注册/登录/登出 50 次无崩溃；接口响应 < 1s

## 自动化接口测试
- 集合：`docs/Phase3_Auth_Test.postman_collection.json`
- 环境：`docs/Phase3_Auth_Test_env.json`
- 运行：
  - `newman run docs/Phase3_Auth_Test.postman_collection.json -e docs/Phase3_Auth_Test_env.json`
  - 通过率必须 100%

## 测试数据
- 用户 A：`testA@example.com` / `GarryA` / `Pass12345`
- 用户 B：`testB@example.com` / `GarryB` / `Pass12345`
- 异常用户：`bad@example` / `badUser` / `123`
- 词卡样例：`leverage`, `exploit`, `sustainability`

## 注意事项
- 生产环境 `AuthService.baseUrl` 应使用 `https://api.english-carousel.com`
- 客户端当前默认 `http://localhost:3000`，发布时请注入生产地址或使用构建环境变量
- 轮播/TTS/缓存与用户切换无耦合，回归验证应保持可播放
- 数据库迁移（增加 `user_id` 外键）需确保旧数据兼容