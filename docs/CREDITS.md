# 第三方开源项目致谢

本项目 **AI编程智驾 (AICoding)** 集成了以下开源项目，感谢他们的贡献：

## 核心集成

| 项目 | 来源 | 许可证 | 用途 |
|------|------|--------|------|
| **gspowers** | https://github.com/fshaan/gspowers | MIT | SOP 流程导航框架 |
| **gstack** | https://github.com/garrytan/gstack | — | 产品流程框架 |
| **Scrapling** | https://github.com/D4Vinci/Scrapling | BSD-3-Clause | Web 爬虫框架，自适应反反爬 + Spider 并发 |
| **frontend-slides** | https://github.com/zarazhangrui/frontend-slides | MIT | HTML 演示文稿生成器 |
| **ruflo** | https://github.com/ruvnet/ruflo | MIT | 多 Agent 编排与记忆系统 |
| **RTK** | https://github.com/rafaelkallis/rtk | MIT | Token 消耗优化 |

## 项目结构致谢

```
AICoding/
├── .claude/skills/
│   ├── kf-prd-generator/       # PRD 生成器（自研）
│   ├── kf-scrapling/           # 基于 D4Vinci/Scrapling
│   ├── gspowers/               # 基于 fshaan/gspowers
│   └── gstack/                 # 基于 garrytan/gstack
├── gspowers-pipeline-patch/    # 基于 fshaan/gspowers 的扩展
└── templates/                  # 配置模板（自研）
```

---

## 各第三方项目 License 说明

### gspowers
- **许可证**: MIT License
- **来源**: https://github.com/fshaan/gspowers
- **描述**: 行业共识的技能规则框架，提供标准化开发流程
- **本项目使用**: Pipeline 多模块流水线的 SOP 导航扩展

### frontend-slides
- **许可证**: MIT License
- **来源**: https://github.com/zarazhangrui/frontend-slides
- **描述**: 零依赖 HTML 演示文稿生成器，支持 PPT 转换
- **本项目使用**: 技能扩展集成

### ruflo
- **许可证**: MIT License
- **来源**: https://github.com/ruvnet/ruflo
- **描述**: AI Agent 编排平台，支持多 Agent 并行/记忆系统
- **本项目使用**: 多 Agent 协同执行框架

### RTK (Rust Token Killer)
- **许可证**: MIT License
- **来源**: https://github.com/rafaelkallis/rtk
- **描述**: CLI 代理工具，大幅降低 Token 消耗
- **本项目使用**: 命令输出压缩与优化

### Scrapling
- **许可证**: BSD-3-Clause License
- **来源**: https://github.com/D4Vinci/Scrapling
- **描述**: 自适应 Web 爬虫框架，支持反反爬绕过（Cloudflare Turnstile）、隐身浏览器、Spider 并发框架
- **本项目使用**: kf-scrapling 技能，作为 /夯 调研阶段的深度数据采集工具

---

## MIT License 原文

以下是各第三方项目适用的 MIT License 条款：

```
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 知识产权说明

1. **本项目的 MIT License** 适用于 AICoding 主项目及其自研部分
2. **第三方项目的 License** 保留各自原作者的版权声明
3. **集成使用** 均遵循各项目对应的 MIT License 条款
4. 如需将本项目用于商业用途，请确保同时遵守各第三方项目的 License

---

*最后更新: 2026-05-02*
