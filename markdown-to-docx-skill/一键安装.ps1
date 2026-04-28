# Markdown 转 DOCX Skill 一键安装脚本
# 双击此脚本或右键选择"使用 PowerShell 运行"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Markdown 转 DOCX Skill 安装程序" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$SourcePath = "D:\projects\AI编程智驾\markdown-to-docx-skill"
$ClaudePath = "C:\Users\KF\.claude\skills\markdown-to-docx"
$TraePath = "C:\Users\KF\.trae\skills\markdown-to-docx"

# 检查源文件是否存在
if (!(Test-Path $SourcePath)) {
    Write-Host "错误：源文件不存在 - $SourcePath" -ForegroundColor Red
    Write-Host "请确保技能文件已下载到指定位置" -ForegroundColor Yellow
    Read-Host "按 Enter 键退出"
    exit 1
}

Write-Host "✓ 找到源文件" -ForegroundColor Green
Write-Host ""

# 安装到 Claude 目录
Write-Host "正在安装到 Claude 目录..." -ForegroundColor Yellow
if (Test-Path $ClaudePath) {
    Write-Host "  检测到已安装，正在更新..." -ForegroundColor Yellow
    Remove-Item -Path $ClaudePath -Recurse -Force
    Write-Host "  ✓ 已删除旧版本" -ForegroundColor Green
}

try {
    Copy-Item -Path $SourcePath -Destination $ClaudePath -Recurse -Force
    Write-Host "  ✓ 成功安装到 Claude" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 安装失败：$_" -ForegroundColor Red
    Write-Host "  请手动复制到：$ClaudePath" -ForegroundColor Yellow
}

Write-Host ""

# 安装到 Trae 目录
Write-Host "正在安装到 Trae 目录..." -ForegroundColor Yellow
if (Test-Path $TraePath) {
    Write-Host "  检测到已安装，正在更新..." -ForegroundColor Yellow
    Remove-Item -Path $TraePath -Recurse -Force
    Write-Host "  ✓ 已删除旧版本" -ForegroundColor Green
}

try {
    Copy-Item -Path $SourcePath -Destination $TraePath -Recurse -Force
    Write-Host "  ✓ 成功安装到 Trae" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 安装失败：$_" -ForegroundColor Red
    Write-Host "  请手动复制到：$TraePath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "安装完成！" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "现在您可以在 Claude 或 Trae 中使用 markdown-to-docx 技能了。" -ForegroundColor White
Write-Host "例如：" -ForegroundColor White
Write-Host '  claude -M "使用 markdown-to-docx 将 README.md 转换为 Word"' -ForegroundColor Gray
Write-Host ""

Read-Host "按 Enter 键退出"
