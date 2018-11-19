$rebar3 = Join-Path -Path $PWD -ChildPath "scripts/rebar3.cmd"

# Install alternate version of rebar3_hex plugin to support "rebar3 hex publish --yes"

New-Item -Path _build/temp -ItemType Directory -EA SilentlyContinue | Out-Null
Push-Location -Path _build/temp

git clone https://github.com/tank-bohr/rebar3_hex.git
Push-Location rebar3_hex
git reset --hard 1befe296033a1a5be888a74848d5d029d6898e88
& $rebar3 compile

Pop-Location
Pop-Location

New-Item -Path "_build/default/plugins/rebar3_hex" -ItemType Directory -EA SilentlyContinue | Out-Null
Copy-Item -Path "_build/temp/rebar3_hex/_build/default/lib/rebar3_hex/*" -Destination "_build/default/plugins/rebar3_hex" -Recurse -Force

Add-Content -Path rebar.config -Value "`r`n{plugins, [rebar3_hex]}."
