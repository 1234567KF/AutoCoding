
后端    Node.js + Express + SQLite
前端	Vue 3 + Vite（运营Web：Ant Design Vue / H5：Vant）
数据库	SQLite 单文件（better-sqlite3，零配置）
基础设施 本地 npm run dev 一键启动
第三方	全部 Mock（签名一致，可切换）
部署	本机运行，无需安装任何外部服务

Demo 阶段优势明显：
单文件数据库，npm run dev 自动创建，无需安装 MySQL
无需配置连接串、端口、用户权限
better-sqlite3 同步 API，代码更简洁
后续切 MySQL 只需换 Drizzle/Knex 的 driver，SQL 无需改动