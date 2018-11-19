rebar3 clean
rebar3 compile
rebar3 eunit

Rename-Item src/expression_lexer.xrl -NewName expression_lexer.leex
Set-Content -Path src/expression_lexer.erl -Value "%% @hidden`r`n$(Get-Content -Path src/expression_lexer.erl -Raw)"

Rename-Item src/expression_parser.yrl -NewName expression_parser.yecc
Set-Content -Path src/expression_parser.erl -Value "%% @hidden`r`n$(Get-Content -Path src/expression_parser.erl -Raw)"

if (Test-Path -Path doc/)
    { Remove-Item -Path doc/ -Recurse -Force }
    
& rebar3 edoc

Rename-Item src/expression_lexer.leex -NewName expression_lexer.xrl
Rename-Item src/expression_parser.yecc -NewName expression_parser.yrl