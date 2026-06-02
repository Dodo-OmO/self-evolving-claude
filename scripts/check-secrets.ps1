# check-secrets.ps1
# 推送公开仓前的「守卫」卡口 —— 三关，任一“拦死”关命中 → 阻止推送（exit 1）。
#   ① 文件内容敏感词：读 secret-patterns.txt 正则扫全仓（排除 .git/node_modules/dist/out）。命中 → 拦死。
#   ② commit 作者/提交者元数据：扫全历史，邮箱非 GitHub noreply（可能泄露真实邮箱进公开提交历史，
#      文件扫描兜不到这层）→ 警示。把真名也加进 secret-patterns.txt 可顺带拦内容层。
#   ③ 悬空 commit：amend / force-push 不会从远端清除旧 commit，含敏感信息的旧版仍可按 SHA 取回 → 警示。
# 用法：pwsh -File scripts/check-secrets.ps1  ｜ 建议接成 git pre-push hook。

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/..").Path
$patternFile = Join-Path $PSScriptRoot 'secret-patterns.txt'

if (-not (Test-Path $patternFile)) {
    Write-Host "[check-secrets] 缺 secret-patterns.txt，跳过内容扫描。" -ForegroundColor Yellow
    $patterns = @()
} else {
    $patterns = Get-Content $patternFile -Encoding UTF8 | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') }
}

$hits = @()

# ── ① 文件内容（拦死）──
if ($patterns) {
    Get-ChildItem $root -Recurse -File |
        Where-Object { $_.FullName -notmatch '[\\/](\.git|node_modules|dist|out)[\\/]' } |
        ForEach-Object {
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { return }
            foreach ($pat in $patterns) {
                if ($content -match $pat) { $hits += "  [内容] $($_.FullName)  ←  /$pat/" }
            }
        }
}

if ($hits.Count -gt 0) {
    Write-Host "[check-secrets] BLOCKED — 文件内容命中敏感模式，禁止推送：" -ForegroundColor Red
    $hits | ForEach-Object { Write-Host $_ }
    exit 1
}

# ── ② commit 作者/提交者元数据（警示）──
$mails = git -C $root log --all --format='%ae%n%ce' 2>$null | Where-Object { $_.Trim() } | Sort-Object -Unique
$realMails = $mails | Where-Object { $_ -notmatch '@users\.noreply\.github\.com$' }
if ($realMails) {
    Write-Host "[check-secrets] ⚠️ commit 历史里有非 GitHub-noreply 邮箱（可能把真实邮箱挂上公开仓）：" -ForegroundColor Yellow
    $realMails | ForEach-Object { Write-Host "     $_" }
    Write-Host "   建议：git config user.email '<id>+<user>@users.noreply.github.com'，必要时重写历史（见 ③ 警示）。" -ForegroundColor Yellow
}

# ── ③ 悬空 commit（警示）──
$dangling = git -C $root fsck --unreachable --no-reflogs 2>$null | Select-String 'unreachable commit'
if ($dangling) {
    Write-Host "[check-secrets] ⚠️ 检测到 $($dangling.Count) 个悬空 commit。" -ForegroundColor Yellow
    Write-Host "   注意：amend / force-push 不会从远端清除旧 commit——含敏感信息的旧版仍可按 SHA 取回。" -ForegroundColor Yellow
    Write-Host "   若曾把敏感内容 amend/force-push 过：删仓 + 零历史重建（fresh git init / orphan 分支）才是唯一干净解。" -ForegroundColor Yellow
}

Write-Host "[check-secrets] OK — 文件内容无敏感命中，可推送（如上有 ⚠️ 请先确认）。" -ForegroundColor Green
exit 0
