Function Get-ProjectDirectory { (Split-Path (Split-Path -parent $PSCommandPath) -parent) }

function Update-eDocVersion {
    Write-Host "Updating documentation version to $env:APPVEYOR_BUILD_NUMBER"

    $pattern = "@version (\d{1,2})\.(\d{1,2})\.(\d{1,2})"
    $newValue = '@version $1.$2.' + $env:APPVEYOR_BUILD_NUMBER

    ((Get-Content -Path "$(Get-ProjectDirectory)\overview.edoc") -replace $pattern, $newValue) | Set-Content -Path "$(Get-ProjectDirectory)\overview.edoc"

    (Get-Content -Path "$(Get-ProjectDirectory)\overview.edoc")    
}

function Update-Documentation {
    Write-Host "Generating documentation"

    Rename-Item src/expression_lexer.xrl -NewName expression_lexer.leex
    Set-Content -Path src/expression_lexer.erl -Value "%% @hidden`r`n$(Get-Content -Path src/expression_lexer.erl -Raw)"

    Rename-Item src/expression_parser.yrl -NewName expression_parser.yecc
    Set-Content -Path src/expression_parser.erl -Value "%% @hidden`r`n$(Get-Content -Path src/expression_parser.erl -Raw)"

    if (Test-Path -Path doc/)
        { Remove-Item -Path doc/ -Recurse -Force }  

    ./scripts/rebar3 edoc

    Rename-Item src/expression_lexer.leex -NewName expression_lexer.xrl
    Rename-Item src/expression_parser.yecc -NewName expression_parser.yrl
}

Update-eDocVersion
Update-Documentation