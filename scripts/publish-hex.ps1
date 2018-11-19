
[CmdletBinding()]
param(
    [string]$username,
    [string]$apiKey
)

$rebar3 = Join-Path -Path $PWD -ChildPath "scripts/rebar3.cmd"

& $rebar3 hex config username $username | Out-Null
& $rebar3 hex config key $apiKey | Out-Null
& $rebar3 hex publish --yes
& $rebar3 hex docs