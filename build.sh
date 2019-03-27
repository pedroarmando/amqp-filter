#!/bin/bash

# Generate Leex lexical analyzer source code

pushd src/ >/dev/nul
erl -pa ebin -noshell -eval "leex:file(expression_lexer)." -eval "init:stop()."
popd >/dev/nul

# Build

./scripts/rebar3 clean
./scripts/rebar3 compile
./scripts/rebar3 eunit

mv src/expression_lexer.xrl src/expression_lexer.leex 
echo "%% @hidden" | cat - src/expression_lexer.erl > src/temp && mv src/temp src/expression_lexer.erl

mv src/expression_parser.yrl src/expression_parser.yecc
echo "%% @hidden" | cat - src/expression_parser.erl > src/temp && mv src/temp src/expression_parser.erl

rm -rf doc

./scripts/rebar3 edoc

mv src/expression_lexer.leex  src/expression_lexer.xrl
mv src/expression_parser.yecc src/expression_parser.yrl
