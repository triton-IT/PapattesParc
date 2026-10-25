param([string]$BaseHref = '/')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
  dart compile js -O2 tool/generation_worker.dart -o web/generation_worker.js
  if ($LASTEXITCODE -ne 0) { throw 'Worker compilation failed' }
  flutter build web --release --base-href $BaseHref
  if ($LASTEXITCODE -ne 0) { throw 'Web compilation failed' }
} finally { Pop-Location }
