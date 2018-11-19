Write-Host "updating version to $env:APPVEYOR_BUILD_NUMBER"

Function Get-ProjectDirectory { (Split-Path (Split-Path -parent $PSCommandPath) -parent) }

$pattern = "{vsn, `"(\d{1,2})\.(\d{1,2})\.(\d{1,2})`"}"
$newValue = '{vsn, "$1.$2.' + $env:APPVEYOR_BUILD_NUMBER + '"}'

((Get-Content -Path "$(Get-ProjectDirectory)\src\amqp_filter.app.src") -replace $pattern, $newValue) | Set-Content -Path "$(Get-ProjectDirectory)\src\amqp_filter.app.src"

(Get-Content -Path "$(Get-ProjectDirectory)\src\amqp_filter.app.src")