$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

python .\setup_kibana_dashboard.py
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
