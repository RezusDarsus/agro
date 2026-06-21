param(
  [string]$Destination = "..\agrolens-samegrelo-release"
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$destinationPath = [System.IO.Path]::GetFullPath((Join-Path $project $Destination))
if (-not $destinationPath.StartsWith((Split-Path $project -Parent))) {
  throw "Release destination must remain beside the project."
}
if (Test-Path $destinationPath) {
  throw "Destination already exists: $destinationPath"
}

$excludeDirectories = @(
  ".dart_tool", "build", ".venv", "__pycache__", ".git",
  "raw_candidates", "quarantine_duplicates"
)
$excludeExtensions = @(".pyc", ".zip")

New-Item -ItemType Directory -Path $destinationPath | Out-Null
Get-ChildItem $project -Recurse -File | Where-Object {
  $relative = $_.FullName.Substring($project.Length).TrimStart('\')
  $segments = $relative.Split('\')
  -not ($segments | Where-Object { $_ -in $excludeDirectories }) -and
  $_.Extension -notin $excludeExtensions
} | ForEach-Object {
  $relative = $_.FullName.Substring($project.Length).TrimStart('\')
  $target = Join-Path $destinationPath $relative
  New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
  Copy-Item -LiteralPath $_.FullName -Destination $target
}

$zip = "$destinationPath.zip"
Compress-Archive -Path "$destinationPath\*" -DestinationPath $zip -CompressionLevel Optimal
Write-Host "Release folder: $destinationPath"
Write-Host "Release ZIP: $zip"
