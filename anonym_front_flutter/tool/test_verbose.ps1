param(
  [switch]$NoCoverage
)

$ErrorActionPreference = "Stop"

Write-Host "==> Running Flutter tests (expanded reporter, single-threaded)..."

$testArgs = @("test", "-r", "expanded", "-j", "1")
if (-not $NoCoverage) {
  $testArgs += "--coverage"
}

flutter @testArgs
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

if ($NoCoverage) {
  Write-Host "`n==> Coverage disabled (--NoCoverage)."
  exit 0
}

$coverageFile = "coverage/lcov.info"
if (-not (Test-Path $coverageFile)) {
  Write-Warning "Coverage file not found: $coverageFile"
  exit 0
}

Write-Host "`n==> Coverage summary from $coverageFile"

$sf = $null
$total = 0
$hit = 0
$files = @{}

Get-Content $coverageFile | ForEach-Object {
  if ($_ -like 'SF:*') {
    $sf = $_.Substring(3)
    if (-not $files.ContainsKey($sf)) {
      $files[$sf] = [PSCustomObject]@{
        Total = 0
        Hit = 0
      }
    }
  } elseif ($_ -like 'DA:*' -and $sf) {
    $parts = $_.Substring(3).Split(',')
    if ($parts.Length -ge 2) {
      $count = [int]$parts[1]
      $total += 1
      $files[$sf].Total += 1
      if ($count -gt 0) {
        $hit += 1
        $files[$sf].Hit += 1
      }
    }
  }
}

$percent = if ($total -eq 0) { 0 } else { [Math]::Round(($hit * 100.0 / $total), 2) }
Write-Host ("TOTAL {0}/{1} = {2}%" -f $hit, $total, $percent)

$table = $files.GetEnumerator() | ForEach-Object {
  $t = $_.Value.Total
  $h = $_.Value.Hit
  $p = if ($t -eq 0) { 0 } else { [Math]::Round(($h * 100.0 / $t), 2) }
  [PSCustomObject]@{
    File = $_.Key
    Hit = $h
    Total = $t
    Percent = $p
  }
}

$table | Sort-Object Percent, Total | Format-Table -AutoSize

# Unit-scope coverage (exclude heavy UI/integration layers)
$unitExcludes = @(
  "lib/screens/",
  "lib/widgets/anonym_map/anonym_map_view_io.dart",
  "lib/widgets/anonym_map/anonym_map_data.dart",
  "lib/widgets/dialogs/anonym_confirm_dialog.dart",
  "lib/widgets/navigation/anonym_back_button.dart",
  "lib/theme.dart",
  "lib/services/socket_service.dart",
  "lib/services/push_notification_service.dart"
)

function Is-UnitExcluded([string]$path) {
  $normalized = $path.Replace('\', '/')
  foreach ($pattern in $unitExcludes) {
    if ($normalized.Contains($pattern)) {
      return $true
    }
  }
  return $false
}

$unitRows = $table | Where-Object { -not (Is-UnitExcluded $_.File) }
$unitHit = ($unitRows | Measure-Object -Property Hit -Sum).Sum
$unitTotal = ($unitRows | Measure-Object -Property Total -Sum).Sum
if (-not $unitHit) { $unitHit = 0 }
if (-not $unitTotal) { $unitTotal = 0 }
$unitPercent = if ($unitTotal -eq 0) { 0 } else { [Math]::Round(($unitHit * 100.0 / $unitTotal), 2) }

Write-Host "`n==> Unit-scope coverage (UI/integration exclusions applied)"
Write-Host ("UNIT {0}/{1} = {2}%" -f $unitHit, $unitTotal, $unitPercent)

$unitRows | Sort-Object Percent, Total | Format-Table -AutoSize


