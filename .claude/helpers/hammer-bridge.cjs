#!/usr/bin/env node
/**
 * hammer-bridge.cjs — /夯 桥接层
 *
 * 桥接 Claude Code 内置 Agent 工具和 ruflo swarm 面板之间的状态鸿沟。
 *
 * 职责：
 *   1. agent-spawn: 记录 Agent 启动（替代 ruflo swarm_init 的面板计数）
 *   2. agent-done:  记录 Agent 完成，更新进度
 *   3. status:      输出当前 /夯 执行状态摘要
 *   4. summary:     生成最终执行摘要
 *
 * 用法：
 *   node .claude/helpers/hammer-bridge.cjs agent-spawn --team red --agent fullstack --task-id T1
 *   node .claude/helpers/hammer-bridge.cjs agent-done --team red --agent fullstack --output red-01.md
 *   node .claude/helpers/hammer-bridge.cjs status
 *   node .claude/helpers/hammer-bridge.cjs summary --task "Claude Code UX改进"
 */

const fs = require('fs');
const path = require('path');

const BRIDGE_DIR = path.resolve(__dirname, '..', '.claude-flow', 'qoder-outputs');
const STATUS_FILE = path.join(BRIDGE_DIR, '.hammer-status.json');
const LOG_FILE = path.join(BRIDGE_DIR, '.hammer-log.jsonl');

// ============ 工具函数 ============

function ensureDir() {
  if (!fs.existsSync(BRIDGE_DIR)) {
    fs.mkdirSync(BRIDGE_DIR, { recursive: true });
  }
}

function readStatus() {
  ensureDir();
  try {
    return JSON.parse(fs.readFileSync(STATUS_FILE, 'utf-8'));
  } catch {
    return {
      task: '',
      phase: 0,
      startedAt: null,
      teams: {},
      totalAgents: 0,
      completedAgents: 0
    };
  }
}

function writeStatus(status) {
  ensureDir();
  fs.writeFileSync(STATUS_FILE, JSON.stringify(status, null, 2), 'utf-8');
}

function appendLog(entry) {
  ensureDir();
  entry.timestamp = new Date().toISOString();
  fs.appendFileSync(LOG_FILE, JSON.stringify(entry) + '\n', 'utf-8');
}

function progressBar(current, total) {
  const width = 20;
  const filled = Math.round((current / total) * width);
  const empty = width - filled;
  return '█'.repeat(filled) + '░'.repeat(empty) + ` ${current}/${total}`;
}

// ============ 命令处理 ============

const args = process.argv.slice(2);
const cmd = args[0];

function getOpt(name) {
  const idx = args.indexOf(`--${name}`);
  return idx >= 0 ? args[idx + 1] : null;
}

switch (cmd) {

  // ---- agent-spawn: 记录 Agent 启动 ----
  case 'agent-spawn': {
    const team = getOpt('team') || 'unknown';
    const agent = getOpt('agent') || 'unknown';
    const taskId = getOpt('task-id') || '?';
    const status = readStatus();

    if (!status.startedAt) {
      status.startedAt = new Date().toISOString();
      status.phase = 2;
    }

    const key = `${team}/${agent}`;
    if (!status.teams[team]) status.teams[team] = { agents: {}, done: 0, total: 0 };
    status.teams[team].agents[agent] = {
      status: 'running',
      taskId,
      startedAt: new Date().toISOString(),
      output: null
    };
    status.teams[team].total = Object.keys(status.teams[team].agents).length;
    status.totalAgents += 1;

    writeStatus(status);
    appendLog({ event: 'agent-spawn', team, agent, taskId });

    console.log(`[hammer-bridge] ${team}/${agent} → spawned (共 ${status.totalAgents} agents)`);
    break;
  }

  // ---- agent-done: 记录 Agent 完成 ----
  case 'agent-done': {
    const team = getOpt('team') || 'unknown';
    const agent = getOpt('agent') || 'unknown';
    const output = getOpt('output') || null;
    const status = readStatus();

    if (status.teams[team] && status.teams[team].agents[agent]) {
      status.teams[team].agents[agent].status = 'done';
      status.teams[team].agents[agent].output = output;
      status.teams[team].agents[agent].completedAt = new Date().toISOString();
      status.teams[team].done += 1;
      status.completedAgents += 1;
    }

    // 检查阶段是否完成
    const totalDone = Object.values(status.teams).reduce((s, t) => s + t.done, 0);
    if (totalDone === status.totalAgents && status.phase === 2) {
      status.phase = 3;
    }

    writeStatus(status);
    appendLog({ event: 'agent-done', team, agent, output });

    console.log(`[hammer-bridge] ${team}/${agent} → done (${status.completedAgents}/${status.totalAgents})`);
    break;
  }

  // ---- status: 输出当前状态 ----
  case 'status': {
    const status = readStatus();

    if (!status.startedAt) {
      console.log('[hammer-bridge] 无正在执行的 /夯 任务');
      console.log('  面板计数: 0/0 (ruflo 桥接模式 — 实际 Agent 通过 Claude Code 内置工具执行)');
      return;
    }

    const elapsed = Date.now() - new Date(status.startedAt).getTime();
    const elapsedStr = `${Math.floor(elapsed / 1000)}s`;

    console.log('');
    console.log('═══════════════════════════════════════════════');
    console.log('  🔨 /夯 执行状态');
    console.log('═══════════════════════════════════════════════');
    console.log(`  任务: ${status.task || '(未命名)'}`);
    console.log(`  阶段: Phase ${status.phase}/4`);
    console.log(`  耗时: ${elapsedStr}`);
    console.log(`  进度: ${progressBar(status.completedAgents, status.totalAgents)}`);
    console.log('');

    for (const [teamName, team] of Object.entries(status.teams)) {
      const done = team.done;
      const total = team.total;
      const icon = done === total ? '✅' : done > 0 ? '🔄' : '⏳';
      console.log(`  ${icon} ${teamName}队: ${progressBar(done, total)}`);
      for (const [agentName, agent] of Object.entries(team.agents)) {
        const s = agent.status === 'done' ? '✅' : agent.status === 'running' ? '🔄' : '⏳';
        console.log(`     ${s} ${agentName} — ${agent.taskId}`);
      }
    }

    console.log('');
    console.log('  注: ruflo swarm 面板显示 0/15 是正常的 — 实际 Agent 通过 Claude Code 内置工具并行执行');
    console.log('═══════════════════════════════════════════════');
    console.log('');
    break;
  }

  // ---- summary: 生成执行摘要 ----
  case 'summary': {
    const task = getOpt('task') || '(未命名)';
    const status = readStatus();

    if (!status.startedAt) {
      console.log('[hammer-bridge] 无执行记录');
      return;
    }

    const elapsed = Date.now() - new Date(status.startedAt).getTime();
    const outputDir = path.join(BRIDGE_DIR, `hammer-${new Date().toISOString().slice(0, 10)}-${task.slice(0, 20).replace(/[^a-zA-Z一-龥]/g, '')}`);
    ensureDir();

    // 扫描输出文件
    const outputFiles = fs.readdirSync(BRIDGE_DIR).filter(f => f.endsWith('-team-final.md'));

    const summaryMd = [
      `# /夯 执行摘要`,
      '',
      `> 任务: ${task}`,
      `> 时间: ${new Date().toISOString().slice(0, 19).replace('T', ' ')}`,
      `> 耗时: ${Math.floor(elapsed / 1000)}s`,
      `> 桥接模式: Claude Code Agent Tools (ruflo 桥接)`,
      '',
      '## 执行统计',
      '',
      `| 指标 | 值 |`,
      `|------|-----|`,
      `| 参与 Agent | ${status.totalAgents} |`,
      `| 完成 Agent | ${status.completedAgents} |`,
      `| 团队数 | ${Object.keys(status.teams).length} |`,
      '',
      '## 团队详情',
      ''
    ];

    for (const [teamName, team] of Object.entries(status.teams)) {
      summaryMd.push(`### ${teamName}队`);
      summaryMd.push('');
      summaryMd.push('| Agent | 状态 | 任务 |');
      summaryMd.push('|-------|------|------|');
      for (const [agentName, agent] of Object.entries(team.agents)) {
        const s = agent.status === 'done' ? '✅' : agent.status === 'running' ? '🔄' : '⏳';
        summaryMd.push(`| ${agentName} | ${s} | ${agent.taskId} |`);
      }
      summaryMd.push('');
    }

    if (outputFiles.length > 0) {
      summaryMd.push('## 产出文件');
      summaryMd.push('');
      outputFiles.forEach(f => summaryMd.push(`- [${f}](${f})`));
    }

    const summaryPath = path.join(BRIDGE_DIR, 'hammer-summary.md');
    fs.writeFileSync(summaryPath, summaryMd.join('\n'), 'utf-8');
    console.log(`[hammer-bridge] 摘要已写入: ${summaryPath}`);
    break;
  }

  // ---- init: 初始化新任务 ----
  case 'init': {
    const task = getOpt('task') || '(未命名)';
    const totalAgents = parseInt(getOpt('total-agents') || '0', 10);

    ensureDir();
    writeStatus({
      task,
      phase: 1,
      startedAt: new Date().toISOString(),
      teams: {},
      totalAgents,
      completedAgents: 0
    });
    appendLog({ event: 'init', task, totalAgents });

    console.log(`[hammer-bridge] 新任务已初始化: ${task} (预期 ${totalAgents} agents)`);
    break;
  }

  default:
    console.log([
      'hammer-bridge.cjs — /夯 桥接层',
      '',
      '用法:',
      '  node .claude/helpers/hammer-bridge.cjs init --task "任务名" --total-agents 11',
      '  node .claude/helpers/hammer-bridge.cjs agent-spawn --team red --agent fullstack --task-id T1',
      '  node .claude/helpers/hammer-bridge.cjs agent-done --team red --agent fullstack --output red-01.md',
      '  node .claude/helpers/hammer-bridge.cjs status',
      '  node .claude/helpers/hammer-bridge.cjs summary --task "任务名"',
    ].join('\n'));
}
