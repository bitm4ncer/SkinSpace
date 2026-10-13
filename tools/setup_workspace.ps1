$ErrorActionPreference = 'Stop'
Set-Location 'C:\GitHub\VLC_Skins'

@'
tools/realesrgan/
research/spike/*.log
research/spike/vlcrc.backup
.superpowers/
*.tmp
'@ | Set-Content -Encoding ASCII .gitignore

if (-not (Test-Path '.git')) { git init -b main | Out-Null }

$ident = (git config user.email) 2>$null
if (-not $ident) {
  git config user.name 'VLC_Skins Build'
  git config user.email 'build@local'
}
"identity: $(git config user.name) <$(git config user.email)>"

git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
  git commit -m 'chore: research baseline (RE docs, spike results, original assets)' | Out-Null
  "baseline commit: $(git rev-parse --short HEAD)"
}

$branch = git rev-parse --abbrev-ref HEAD
if ($branch -eq 'main') { git checkout -b headspace-port | Out-Null }
"branch: $(git rev-parse --abbrev-ref HEAD)"

$S = '/c/Users/konta/.cache/opencode/npm/git-superpowers-0958a5557860/1791469314769/node_modules/superpowers/skills'
$bash = 'C:\Program Files\Git\bin\bash.exe'

$ws = & $bash -c "cd /c/GitHub/VLC_Skins && '$S/subagent-driven-development/scripts/sdd-workspace' 'docs/superpowers/plans/2026-10-13-headspace-vlc-skin-plan.md'"
"workspace: $ws"

& $bash -c "cd /c/GitHub/VLC_Skins && '$S/executing-plans/scripts/task-start' 'docs/superpowers/plans/2026-10-13-headspace-vlc-skin-plan.md' 1"
