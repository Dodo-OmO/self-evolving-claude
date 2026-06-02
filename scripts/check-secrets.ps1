# check-secrets.ps1
# 推送到公开仓前的敏感词扫描卡口。命中任一模式 → 列出并 exit 1（阻止推送）。
# 读 scripts/secret-patterns.txt（每行一个正则，'#' 注释），扫全仓（排除 .git/node_modules/dist/out）。
#
# 用法：pwsh -File scripts/check-secrets.ps1
# 建议接成 git pre-push hook，或发布脚本里 push 前先跑。

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/..").Path
$patternFile = Join-Path $PSScriptRoot 'secret-patterns.txt'

if (-not (Test-Path $patternFile)) {
    Write-Host "[check-secrets] 缺 secret-patterns.txt，跳过。" -ForegroundColor Yellow
    exit 0
}

$patterns = Get-Content $patternFile -Encoding UTF8 | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') }
if (-not $patterns) { exit 0 }

$hits = @()
Get-ChildItem $root -Recurse -File |
    Where-Object { $_.FullName -notmatch '[\\/](\.git|node_modules|dist|out)[\\/]' } |
    ForEach-Object {
        $file = $_
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { return }
        foreach ($pat in $patterns) {
            if ($content -match $pat) {
                $hits += "  $($file.FullName)  ←  /$pat/"
            }
        }
    }

if ($hits.Count -gt 0) {
    Write-Host "[check-secrets] BLOCKED — 命中敏感模式，禁止推送：" -ForegroundColor Red
    $hits | ForEach-Object { Write-Host $_ }
    exit 1
}

Write-Host "[check-secrets] OK — 无敏感模式命中，可推送。" -ForegroundColor Green
exit 0
