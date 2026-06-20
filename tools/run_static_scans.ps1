[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$requiredPaths = @(
	"project.godot",
	"addons/gut/gut_cmdln.gd",
	"tests/static"
)
$missingPaths = @()

foreach ($relativePath in $requiredPaths) {
	$absolutePath = Join-Path $projectRoot $relativePath
	if (-not (Test-Path -LiteralPath $absolutePath)) {
		$missingPaths += $relativePath
	}
}

if ($missingPaths.Count -gt 0) {
	Write-Error "M0 static scan bootstrap prerequisites are missing: $($missingPaths -join ', ')"
	exit 1
}

Write-Host "M0 bootstrap wrapper only: prerequisites are present."
Write-Host "Real static scans are not implemented in M0 and will be added in future milestones."
exit 0
