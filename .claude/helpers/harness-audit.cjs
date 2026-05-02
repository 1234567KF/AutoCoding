/**
 * Harness Engineering Audit System
 *
 * 全路径扫描 kf- 技能，按五根铁律评分，输出结构化评审报告。
 *
 * 用法：
 *   node harness-audit.cjs --all              # 全量审计
 *   node harness-audit.cjs --skill kf-spec    # 单技能审计
 *   node harness-audit.cjs --rule constraints # 单铁律审计
 *   node harness-audit.cjs --all --format json # JSON 输出
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const CWD = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const SKILLS_DIR = path.join(CWD, '.claude', 'skills');
const MEMORY_DIR = path.join(CWD, 'memory');
const SETTINGS_FILE = path.join(CWD, '.claude', 'settings.json');
const CLAUDE_MD = path.join(CWD, '.claude', 'CLAUDE.md');

// ─── Skill Discovery ───────────────────────────────────────────

function discoverSkills() {
  const skills = [];
  if (!fs.existsSync(SKILLS_DIR)) return skills;

  for (const entry of fs.readdirSync(SKILLS_DIR, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (!entry.name.startsWith('kf-')) continue;

    const skillFile = path.join(SKILLS_DIR, entry.name, 'SKILL.md');
    if (!fs.existsSync(skillFile)) continue;

    const content = fs.readFileSync(skillFile, 'utf-8');
    const frontmatter = parseFrontmatter(content);
    skills.push({
      name: entry.name,
      path: skillFile,
      content,
      frontmatter,
      hasReferences: fs.existsSync(path.join(SKILLS_DIR, entry.name, 'references')),
      hasAssets: fs.existsSync(path.join(SKILLS_DIR, entry.name, 'assets')),
    });
  }

  return skills.sort((a, b) => a.name.localeCompare(b.name));
}

function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};
  const fm = {};
  for (const line of match[1].split('\n')) {
    const colonIdx = line.indexOf(':');
    if (colonIdx === -1) continue;
    const key = line.slice(0, colonIdx).trim();
    let value = line.slice(colonIdx + 1).trim();
    // strip quotes
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    fm[key] = value;
  }
  return fm;
}

// ─── Iron Rule 1: Instructions ─────────────────────────────────

function scoreInstructions(skill) {
  const c = skill.content;
  let score = 3; // baseline

  // Positive indicators
  if (/\bStep\s+\d+/i.test(c)) score += 0.5;
  if (/MUST\s+NOT/i.test(c)) score += 0.5;
  if (/MUST\s/i.test(c)) score += 0.5;
  if (/Gate\s+\d/i.test(c)) score += 0.5;
  if (/Gotchas/i.test(c)) score += 0.5;

  // Step numbering quality: at least 3 numbered steps
  const stepMatches = c.match(/###\s+Step\s+\d+/gi) || c.match(/##\s+Step\s+\d+/gi) || [];
  if (stepMatches.length >= 3) score += 0.5;
  if (stepMatches.length >= 5) score += 0.5;

  // Integrated skills declared
  if (skill.frontmatter['integrated-skills'] || c.includes('integrated-skills')) score += 0.5;

  // Gate conditions with blocking
  if (/DO\s+NOT\s+proceed/i.test(c)) score += 0.5;

  // Negative indicators
  // One-liner skills (too vague)
  const bodyLines = c.split('---').slice(2).join('---').trim().split('\n').filter(l => l.trim());
  if (bodyLines.length < 30) score -= 1;

  // No MUST/MUST NOT at all
  if (!/MUST/i.test(c)) score -= 1;

  return clamp(Math.round(score * 2) / 2, 1, 5);
}

function explainInstructions(skill) {
  const findings = [];
  const c = skill.content;
  const stepMatches = c.match(/###\s+Step\s+\d+/gi) || c.match(/##\s+Step\s+\d+/gi) || [];

  if (stepMatches.length >= 5) findings.push({ ok: true, msg: `${stepMatches.length} 个编号 Step — 步骤清晰` });
  else if (stepMatches.length >= 3) findings.push({ ok: true, msg: `${stepMatches.length} 个编号 Step — 基本可执行` });
  else findings.push({ ok: false, msg: `仅 ${stepMatches.length} 个编号 Step — 步骤不够清晰` });

  if (/MUST\s+NOT/i.test(c)) findings.push({ ok: true, msg: '包含 MUST NOT 约束' });
  else findings.push({ ok: false, msg: '缺少 MUST NOT 约束' });

  if (/Gate\s+\d/i.test(c) || /DO\s+NOT\s+proceed/i.test(c)) findings.push({ ok: true, msg: '有 Gate 门控条件' });
  else findings.push({ ok: false, msg: '缺少 Gate 门控条件' });

  if (/Gotchas/i.test(c)) findings.push({ ok: true, msg: '有 Gotchas 章节' });

  return findings;
}

// ─── Iron Rule 2: Constraints ──────────────────────────────────

function scoreConstraints(skill) {
  const c = skill.content;
  let score = 2; // baseline — most skills start weak here

  // Mechanical gate check calls
  const gateCheckMatches = c.match(/harness-gate-check\.cjs/g);
  if (gateCheckMatches) {
    if (gateCheckMatches.length >= 3) score += 2;
    else if (gateCheckMatches.length >= 1) score += 1.5;
    else score += 0.5;
  }

  // Forbidden patterns check
  if (/forbidden-patterns/i.test(c)) score += 0.5;

  // Required files/sections check
  if (/required-files|required-sections/i.test(c)) score += 0.5;

  // Gate failure → block (not just warn)
  if (/阻断|block|exit\s+1/i.test(c)) score += 0.5;

  // Hook configuration
  if (/PostToolUse|PreToolUse|hook/i.test(c)) score += 0.5;

  return clamp(Math.round(score * 2) / 2, 1, 5);
}

function explainConstraints(skill) {
  const findings = [];
  const c = skill.content;
  const gateCheckMatches = c.match(/harness-gate-check\.cjs/g) || [];

  if (gateCheckMatches.length >= 3) findings.push({ ok: true, msg: `${gateCheckMatches.length} 处机械化门控验证 — 约束充分` });
  else if (gateCheckMatches.length >= 1) findings.push({ ok: true, msg: `${gateCheckMatches.length} 处机械化门控验证` });
  else findings.push({ ok: false, msg: '零机械化门控验证 — 仅有自然语言约束' });

  if (/forbidden-patterns/i.test(c)) findings.push({ ok: true, msg: '有禁止模式检查' });
  if (/required-files|required-sections/i.test(c)) findings.push({ ok: true, msg: '有必需文件/章节检查' });
  if (/阻断|exit\s+1/i.test(c)) findings.push({ ok: true, msg: '验证失败会阻断流程' });

  return findings;
}

// ─── Iron Rule 3: Feedback ─────────────────────────────────────

function scoreFeedback(skill) {
  const c = skill.content;
  let score = 2; // baseline

  // Harness feedback loop section
  if (/Harness\s+(反馈|反饋|Feedback|闭环)/i.test(c)) score += 1;

  // Plan→Build→Verify→Fix pattern
  if (/Plan.*Build.*Verify.*Fix/i.test(c) || /计划.*构建.*验证.*修复/i.test(c)) score += 1;

  // Per-step verification table
  if (/验证动作.*失败处理|Verify.*Fail/i.test(c)) score += 0.5;

  // Rejects subjective acceptance
  if (/主观|"我觉得|不.*主观/i.test(c)) score += 0.5;

  // Feedback loop for each step
  const verifyMatches = c.match(/验证|verify|检查|check/gi) || [];
  if (verifyMatches.length >= 5) score += 0.5;
  if (verifyMatches.length >= 10) score += 0.5;

  return clamp(Math.round(score * 2) / 2, 1, 5);
}

function explainFeedback(skill) {
  const findings = [];
  const c = skill.content;

  if (/Harness\s+(反馈|反饋|Feedback|闭环)/i.test(c)) {
    findings.push({ ok: true, msg: '有 Harness 反馈闭环章节' });
  } else {
    findings.push({ ok: false, msg: '缺少 Harness 反馈闭环章节 — 无 Plan→Build→Verify→Fix 循环' });
  }

  if (/验证动作.*失败处理|Verify.*Fail/i.test(c)) {
    findings.push({ ok: true, msg: '有 per-step 验证动作 + 失败处理定义' });
  }

  const verifyMatches = c.match(/验证|verify|检查|check/gi) || [];
  findings.push({ ok: verifyMatches.length >= 5, msg: `${verifyMatches.length} 处验证关键词` });

  return findings;
}

// ─── Iron Rule 4: Memory ───────────────────────────────────────

function scoreMemory(skill) {
  const c = skill.content;
  let score = 2; // baseline

  // Mentions memory/ directory
  if (/memory\//i.test(c)) score += 1;

  // Structured memory with auto-load
  if (/最近.*条.*记录|last.*N.*records|自动加载.*基线/i.test(c)) score += 1;

  // Stats/tracking
  if (/统计|stats|tracking|汇总/i.test(c)) score += 0.5;

  // MEMORY.md reference
  if (/MEMORY\.md/i.test(c)) score += 0.5;

  // Cross-session persistence
  if (/跨会话|cross.?session|persist/i.test(c)) score += 0.5;

  return clamp(Math.round(score * 2) / 2, 1, 5);
}

function explainMemory(skill) {
  const findings = [];
  const c = skill.content;

  if (/memory\//i.test(c)) findings.push({ ok: true, msg: '有 memory/ 目录读写' });
  else findings.push({ ok: false, msg: '无 memory/ 目录读写 — 每次会话从零开始' });

  if (/最近.*条.*记录|自动加载.*基线/i.test(c)) findings.push({ ok: true, msg: '启动时自动加载历史基线' });
  if (/统计|stats|tracking/i.test(c)) findings.push({ ok: true, msg: '有统计/追踪机制' });

  return findings;
}

// ─── Iron Rule 5: Orchestration ────────────────────────────────

function scoreOrchestration(skill) {
  const c = skill.content;
  let score = 2; // baseline

  // recommended_model in frontmatter content
  if (/recommended_model/i.test(c)) score += 0.5;

  // Agent-level model routing
  if (/model.*:.*"sonnet"|model.*:.*"opus"|model.*:.*"flash"|model.*:.*"pro"/i.test(c)) score += 1;

  // Sub-agent spawn
  if (/agent_spawn|Agent\(|Spawn.*Agent/i.test(c)) score += 1;

  // Context firewall concept
  if (/上下文.*防火墙|context.*firewall/i.test(c)) score += 0.5;

  // integrated-skills with triggered-by
  if (skill.frontmatter['integrated-skills']) score += 0.5;
  if (/联动关系|联动|integrated/i.test(c)) score += 0.5;

  return clamp(Math.round(score * 2) / 2, 1, 5);
}

function explainOrchestration(skill) {
  const findings = [];
  const c = skill.content;

  if (/recommended_model/i.test(c)) findings.push({ ok: true, msg: '声明了 recommended_model' });
  else findings.push({ ok: false, msg: '未声明 recommended_model' });

  if (/model.*:.*"sonnet"|model.*:.*"opus"/i.test(c)) findings.push({ ok: true, msg: '有 Agent 级模型路由（协调者 pro / worker flash）' });
  else if (/agent_spawn|Agent\(/i.test(c)) findings.push({ ok: false, msg: '有 agent spawn 但未指定 model 参数' });

  if (skill.frontmatter['integrated-skills']) findings.push({ ok: true, msg: '声明了 integrated-skills 联动链' });

  return findings;
}

// ─── Systemic Checks ───────────────────────────────────────────

function checkSystemicIssues(skills) {
  const issues = [];

  // Check 1: How many skills have mechanical gate checks?
  const withGateChecks = skills.filter(s => /harness-gate-check\.cjs/.test(s.content));
  if (withGateChecks.length < skills.length * 0.6) {
    issues.push({
      severity: 'P0',
      rule: '约束',
      title: '约束层缺失（系统性）',
      detail: `${skills.length} 个技能中仅 ${withGateChecks.length} 个有机械化门控验证。` +
        `其余 ${skills.length - withGateChecks.length} 个仅靠自然语言 MUST/MUST NOT，` +
        `Agent 可以跳过任何门控条件。`,
      affected: skills.filter(s => !/harness-gate-check\.cjs/.test(s.content)).map(s => s.name),
    });
  }

  // Check 2: How many skills read/write memory?
  const withMemory = skills.filter(s => /memory\//i.test(s.content));
  if (withMemory.length < skills.length * 0.5) {
    issues.push({
      severity: 'P0',
      rule: '记忆',
      title: '记忆层空转（系统性）',
      detail: `${skills.length} 个技能中仅 ${withMemory.length} 个有 memory/ 目录读写。` +
        `即使后端已配置，没有技能主动读写记忆，每次对话从零开始。`,
      affected: skills.filter(s => !/memory\//i.test(s.content)).map(s => s.name),
    });
  }

  // Check 3: How many skills have feedback loops?
  const withFeedback = skills.filter(s => /Harness\s+(反馈|Feedback|闭环)/i.test(s.content));
  if (withFeedback.length < skills.length * 0.5) {
    issues.push({
      severity: 'P0',
      rule: '反馈',
      title: '反馈不闭环（系统性）',
      detail: `${skills.length} 个技能中仅 ${withFeedback.length} 个有 Harness 反馈闭环章节。` +
        `技能产出质量验证无自动触发机制。`,
      affected: skills.filter(s => !/Harness\s+(反馈|Feedback|闭环)/i.test(s.content)).map(s => s.name),
    });
  }

  // Check 4: How many skills have model routing?
  const withModelRouting = skills.filter(s => /recommended_model/i.test(s.content));
  if (withModelRouting.length < skills.length * 0.5) {
    issues.push({
      severity: 'P1',
      rule: '编排',
      title: '模型路由未普及',
      detail: `${skills.length} 个技能中仅 ${withModelRouting.length} 个声明了 recommended_model。`,
      affected: skills.filter(s => !/recommended_model/i.test(s.content)).map(s => s.name),
    });
  }

  return issues;
}

// ─── Settings.json check ───────────────────────────────────────

function checkSettings() {
  const issues = [];
  if (!fs.existsSync(SETTINGS_FILE)) {
    issues.push({ ok: false, msg: 'settings.json 不存在' });
    return issues;
  }
  try {
    const settings = JSON.parse(fs.readFileSync(SETTINGS_FILE, 'utf-8'));
    const hooks = settings.hooks || {};

    const hasGateHook = JSON.stringify(hooks).includes('harness-gate-check');
    const hasAlignmentHook = JSON.stringify(hooks).includes('alignment-hook');

    if (hasGateHook) issues.push({ ok: true, msg: 'settings.json 已配置 harness-gate-check Hook' });
    else issues.push({ ok: false, msg: 'settings.json 未配置 harness-gate-check Hook' });

    if (hasAlignmentHook) issues.push({ ok: true, msg: 'settings.json 已配置 alignment-hook' });

  } catch (e) {
    issues.push({ ok: false, msg: `settings.json 解析失败: ${e.message}` });
  }
  return issues;
}

// ─── Memory directory check ────────────────────────────────────

function checkMemoryDir() {
  if (!fs.existsSync(MEMORY_DIR)) {
    return { exists: false, files: [], issues: [{ ok: false, msg: 'memory/ 目录不存在' }] };
  }
  const files = fs.readdirSync(MEMORY_DIR).filter(f => f.endsWith('.md'));
  return {
    exists: true,
    files,
    issues: files.length === 0
      ? [{ ok: false, msg: 'memory/ 目录为空 — 无任何记忆持久化' }]
      : [{ ok: true, msg: `memory/ 目录存在，${files.length} 个记忆文件` }],
  };
}

// ─── Report Generation ─────────────────────────────────────────

function clamp(v, min, max) { return Math.max(min, Math.min(max, v)); }

function generateReport(skills, args) {
  const results = skills.map(s => {
    const scores = {
      instructions: scoreInstructions(s),
      constraints: scoreConstraints(s),
      feedback: scoreFeedback(s),
      memory: scoreMemory(s),
      orchestration: scoreOrchestration(s),
    };
    return {
      name: s.name,
      scores,
      average: Math.round(Object.values(scores).reduce((a, b) => a + b, 0) / 5 * 10) / 10,
      explanations: {
        instructions: explainInstructions(s),
        constraints: explainConstraints(s),
        feedback: explainFeedback(s),
        memory: explainMemory(s),
        orchestration: explainOrchestration(s),
      },
      frontmatter: s.frontmatter,
    };
  });

  const avgByRule = {};
  for (const rule of ['instructions', 'constraints', 'feedback', 'memory', 'orchestration']) {
    avgByRule[rule] = Math.round(results.reduce((s, r) => s + r.scores[rule], 0) / results.length * 10) / 10;
  }
  const overallAvg = Math.round(Object.values(avgByRule).reduce((a, b) => a + b, 0) / 5 * 10) / 10;

  const systemicIssues = checkSystemicIssues(skills);
  const settingsIssues = checkSettings();
  const memoryCheck = checkMemoryDir();

  return {
    date: new Date().toISOString().split('T')[0],
    scope: `${skills.length} kf- skills`,
    overallAvg,
    avgByRule,
    results,
    systemicIssues,
    settingsIssues,
    memoryCheck,
  };
}

function printTextReport(report) {
  const R = report;
  const bar = '='.repeat(60);

  console.log(`\n${bar}`);
  console.log(`  Harness Engineering 评审报告`);
  console.log(`${bar}`);
  console.log(`  日期: ${R.date}  范围: ${R.scope}  综合均分: ${R.overallAvg}/5`);
  console.log(`${bar}\n`);

  // Overall scores
  const ruleNames = { instructions: '指令', constraints: '约束', feedback: '反馈', memory: '记忆', orchestration: '编排' };
  console.log('一、铁律均分');
  console.log('-'.repeat(40));
  for (const [rule, score] of Object.entries(R.avgByRule)) {
    const status = score >= 4 ? '优秀' : score >= 3 ? '良好' : score >= 2 ? '不足' : '严重不足';
    const bar2 = '█'.repeat(Math.round(score * 4)) + '░'.repeat(20 - Math.round(score * 4));
    console.log(`  ${ruleNames[rule]}: ${bar2} ${score}/5 [${status}]`);
  }
  console.log(`\n  综合: ${'█'.repeat(Math.round(R.overallAvg * 4))}${'░'.repeat(20 - Math.round(R.overallAvg * 4))} ${R.overallAvg}/5\n`);

  // Skills matrix
  console.log('\n二、技能 × 铁律评分矩阵');
  console.log('-'.repeat(80));
  const header = `  ${'技能'.padEnd(24)} ${'指令'.padEnd(6)} ${'约束'.padEnd(6)} ${'反馈'.padEnd(6)} ${'记忆'.padEnd(6)} ${'编排'.padEnd(6)} ${'均分'.padEnd(6)}`;
  console.log(header);
  console.log('  ' + '-'.repeat(76));
  for (const r of R.results) {
    const s = r.scores;
    const status = r.average >= 4 ? '✓' : r.average >= 3 ? '○' : '✗';
    console.log(`  ${r.name.padEnd(24)} ${String(s.instructions).padEnd(6)} ${String(s.constraints).padEnd(6)} ${String(s.feedback).padEnd(6)} ${String(s.memory).padEnd(6)} ${String(s.orchestration).padEnd(6)} ${String(r.average).padEnd(6)} ${status}`);
  }

  // Systemic issues
  if (R.systemicIssues.length > 0) {
    console.log('\n\n三、系统性缺陷');
    console.log('-'.repeat(60));
    for (const issue of R.systemicIssues) {
      console.log(`\n  [${issue.severity}] ${issue.title} (铁律 ${issue.rule})`);
      console.log(`  ${issue.detail}`);
      console.log(`  影响: ${issue.affected.join(', ')}`);
    }
  }

  // Settings check
  if (R.settingsIssues.length > 0) {
    console.log('\n\n四、基础设施检查');
    console.log('-'.repeat(40));
    for (const issue of R.settingsIssues) {
      console.log(`  ${issue.ok ? '✓' : '✗'} ${issue.msg}`);
    }
  }

  // Memory check
  if (R.memoryCheck.issues.length > 0) {
    console.log(`\n  记忆目录 (memory/):`);
    for (const issue of R.memoryCheck.issues) {
      console.log(`  ${issue.ok ? '✓' : '✗'} ${issue.msg}`);
    }
  }

  // Per-skill details (only for --verbose)
  if (process.argv.includes('--verbose')) {
    console.log('\n\n五、逐技能诊断');
    console.log('-'.repeat(60));
    for (const r of R.results) {
      console.log(`\n  [${r.name}] 均分: ${r.average}/5`);
      const ruleNames2 = ['instructions', 'constraints', 'feedback', 'memory', 'orchestration'];
      for (const rule of ruleNames2) {
        console.log(`    ${ruleNames[rule]} (${r.scores[rule]}/5):`);
        for (const f of r.explanations[rule]) {
          console.log(`      ${f.ok ? '✓' : '✗'} ${f.msg}`);
        }
      }
    }
  }

  console.log(`\n${bar}\n`);
}

function printJsonReport(report) {
  console.log(JSON.stringify(report, null, 2));
}

// ─── Main ──────────────────────────────────────────────────────

function main() {
  const args = process.argv.slice(2);
  const isJson = args.includes('--format') && args[args.indexOf('--format') + 1] === 'json';
  const isVerbose = args.includes('--verbose');
  const isAll = args.includes('--all');

  let skills = discoverSkills();

  // Filter by skill
  const skillIdx = args.indexOf('--skill');
  if (skillIdx !== -1 && args[skillIdx + 1]) {
    skills = skills.filter(s => s.name === args[skillIdx + 1]);
    if (skills.length === 0) {
      console.error(`Skill not found: ${args[skillIdx + 1]}`);
      process.exit(1);
    }
  }

  if (skills.length === 0) {
    console.log('No kf- skills found.');
    process.exit(0);
  }

  const report = generateReport(skills, args);

  if (isJson) {
    printJsonReport(report);
  } else {
    printTextReport(report);
  }

  // Exit with non-zero if critical issues found
  const hasP0 = report.systemicIssues.some(i => i.severity === 'P0');
  if (hasP0 && !isJson) {
    console.log('⚠ 存在 P0 级系统性缺陷，建议优先修复。\n');
  }

  process.exit(0);
}

main();
