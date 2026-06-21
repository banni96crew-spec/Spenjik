[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

function Get-ProjectRelativePath {
	param([Parameter(Mandatory = $true)][string]$FullName)

	$resolvedRoot = [System.IO.Path]::GetFullPath($projectRoot).TrimEnd("\", "/")
	$resolvedPath = [System.IO.Path]::GetFullPath($FullName)
	if (-not $resolvedPath.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
		throw "Path is outside project root: $resolvedPath"
	}
	return $resolvedPath.Substring($resolvedRoot.Length).TrimStart("\", "/").Replace("\", "/")
}

$requiredPaths = @(
	"project.godot",
	"addons/gut/gut_cmdln.gd",
	"tests/static",
	"tests/integration",
	"tests/replay"
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

$sourceFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter "*.gd" -File |
	Where-Object {
		$relativePath = Get-ProjectRelativePath -FullName $_.FullName
		-not $relativePath.StartsWith("addons/gut/") -and
		-not $relativePath.StartsWith(".godot/")
	}

$oversizedFiles = @()
foreach ($sourceFile in $sourceFiles) {
	$lineCount = (Get-Content -LiteralPath $sourceFile.FullName).Count
	if ($lineCount -ge 250) {
		$relativePath = Get-ProjectRelativePath -FullName $sourceFile.FullName
		$oversizedFiles += "$relativePath ($lineCount lines)"
	}
}

if ($oversizedFiles.Count -gt 0) {
	Write-Error "Source files must stay below 250 lines: $($oversizedFiles -join ', ')"
	exit 1
}

$markerFiles = Get-ChildItem -Path @(
	(Join-Path $projectRoot "data"),
	(Join-Path $projectRoot "logic"),
	(Join-Path $projectRoot "autoload"),
	(Join-Path $projectRoot "scenes"),
	(Join-Path $projectRoot "tests"),
	(Join-Path $projectRoot "docs/prd")
) -Recurse -File -ErrorAction SilentlyContinue |
	Where-Object {
		$relativePath = Get-ProjectRelativePath -FullName $_.FullName
		$markerDefinitionFiles = @(
			"docs/prd/18_TEST_PLAN.md",
			"docs/prd/20_LLM_AGENT_RULES.md",
			"docs/prd/21_OPEN_QUESTIONS_AND_FIXES.md"
		)
		$_.Extension -in @(".gd", ".tscn", ".tres", ".md") -and
		$relativePath -notin $markerDefinitionFiles
	}

$untrackedMarkers = @()
foreach ($markerFile in $markerFiles) {
	$lineNumber = 0
	foreach ($line in Get-Content -LiteralPath $markerFile.FullName) {
		$lineNumber += 1
		if ($line -match "TODO|TBD|FIXME|\?\?\?" -and $line -notmatch "OQ-\d{3}") {
			$relativePath = Get-ProjectRelativePath -FullName $markerFile.FullName
			$untrackedMarkers += "${relativePath}:${lineNumber}"
		}
	}
}

if ($untrackedMarkers.Count -gt 0) {
	Write-Error "Untracked ambiguity markers found: $($untrackedMarkers -join ', ')"
	exit 1
}

$forbiddenRandomPatterns = @(
	"randf(",
	"randi(",
	"randi_range(",
	"randomize(",
	"RandomNumberGenerator",
	"Time.get_ticks",
	"Time.get_unix_time",
	"Time.get_datetime",
	"OS.get_ticks",
	"get_ticks_msec",
	"get_ticks_usec"
)
$forbiddenRandomUsages = @()
foreach ($sourceFile in $sourceFiles) {
	$relativePath = Get-ProjectRelativePath -FullName $sourceFile.FullName
	if ($relativePath.StartsWith("tests/")) {
		continue
	}
	$lineNumber = 0
	foreach ($line in Get-Content -LiteralPath $sourceFile.FullName) {
		$lineNumber += 1
		foreach ($pattern in $forbiddenRandomPatterns) {
			if ($line.Contains($pattern)) {
				$forbiddenRandomUsages += "${relativePath}:${lineNumber}"
			}
		}
	}
}

if ($forbiddenRandomUsages.Count -gt 0) {
	Write-Error "Forbidden random APIs found: $($forbiddenRandomUsages -join ', ')"
	exit 1
}

$forbiddenExtensions = @(".js", ".jsx", ".ts", ".tsx")
$forbiddenNames = @("package.json", "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "Dockerfile")
$forbiddenArtifacts = Get-ChildItem -Path $projectRoot -Recurse -File |
	Where-Object {
		$relativePath = Get-ProjectRelativePath -FullName $_.FullName
		-not $relativePath.StartsWith(".cursor/") -and
		-not $relativePath.StartsWith(".git/") -and
		-not $relativePath.StartsWith("docs/") -and
		-not $relativePath.StartsWith("addons/gut/") -and
		($_.Extension -in $forbiddenExtensions -or $_.Name -in $forbiddenNames)
	} |
	ForEach-Object { Get-ProjectRelativePath -FullName $_.FullName }

if ($forbiddenArtifacts.Count -gt 0) {
	Write-Error "Forbidden web-stack artifacts found: $($forbiddenArtifacts -join ', ')"
	exit 1
}

Write-Host "M1 file-length scan passed: $($sourceFiles.Count) project GDScript files checked."
Write-Host "M1 open-question marker scan passed: $($markerFiles.Count) project files checked."
Write-Host "M1 forbidden-random scan passed."
Write-Host "M1 banned-stack scan passed."
exit 0
