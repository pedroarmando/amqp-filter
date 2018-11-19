-module(expression_parser_test).
-include_lib("eunit/include/eunit.hrl").
-compile(nowarn_unused_function).

% EUnit Tests

is_null_test() ->
    { is_null, { property, "PROP" }} = get_ast("PROP IS NULL").

is_not_null_test() ->
    { is_not_null, { property, "PROP" }} = get_ast("PROP IS NOT NULL").

is_not_null_with_scope_test() ->
    { is_not_null, { property, "PROP2" }} = get_ast("PROP1.[PROP2] IS NOT NULL").

exist_test() ->
    { exists, { property, "PROP" }} = get_ast("EXISTS (PROP)").

comparison_operator_expression_test() ->
    { eq, _, _ } = get_ast("PROP1 = [PROP2]"),
    { neq, _, _ } = get_ast("PROP1 <> [PROP2]"),
    { neq, _, _ } = get_ast("PROP1 != [PROP2]"),
    { gt, _, _ } = get_ast("PROP1 > [PROP2]"),
    { gte, _, _ } = get_ast("PROP1 >= [PROP2]"),
    { lt, _, _ } = get_ast("PROP1 < [PROP2]"),
    { lte, _, _ } = get_ast("PROP1 <= [PROP2]").

integer_constant_expression_test() ->
    { _, _, { integer_constant, "123" }} = get_ast("PROP = 123").

decimal_constant_expression_test() ->
    { _, _, { decimal_constant, "2.5" }} = get_ast("PROP = 2.5").

approximate_number_constant_expression_test() ->
    { _, _, { approximate_number_constant, "101.5E5" }} = get_ast("PROP = 101.5E5").

boolean_constant_expression_test() ->
    { _, _, { boolean_constant, "TRUE" }} = get_ast("PROP = TRUE").

string_constant_expression_test() ->
    { _, _, { string_constant, "CONSTANT_VALUE" }} = get_ast("PROP = 'CONSTANT_VALUE'").

expression_between_parentheses_test() ->
    { eq, { property, "PROP"}, { integer_constant, "123" }} = get_ast("PROP = (123)").

plus_expression_test() ->
    { _, _, { plus, _ }} = get_ast("PROP = +2.5").

minus_expression_test() ->
        { _, _, { minus, _ }} = get_ast("PROP = -2.5").

expression_add_test() -> 
    { _, _, { addition, _, _ }} = get_ast("PROP = A + B").

expression_subtraction_test() -> 
    { _, _, { subtraction, _, _ }} = get_ast("PROP = A - B").

expression_multiplication_test() -> 
    { _, _, { multiplication, _, _ }} = get_ast("PROP = A * B").

expression_division_test() -> 
    { _, _, { division, _, _ }} = get_ast("PROP = A / B").


expression_remainder_test() -> 
    { _, _, { remainder, _, _ }} = get_ast("PROP = A % B").

predicate_between_parenteses_test() -> 
    { eq, _, _ } = get_ast("(PROP = 34)").

not_predicate_test() ->
    { not_op, _} = get_ast("NOT A = B").

predicate_and_predicate_test() -> 
    { and_op, _, _ } = get_ast("A = B AND B = C").

predicate_or_predicate_test() -> 
    { or_op, _, _ } = get_ast("A = B OR B = C").

expression_in_expression_test() ->
    { in, { property, "A" }, [ { property, "A" } ]} = get_ast("A IN (A)").

expression_in_expression_list_test() ->
    { _, _, [{ property, "A"}, { property, "B" }]} = get_ast("A IN (A, B)").

expression_not_in_expression_test() ->
    { not_in, _, _ } = get_ast("A NOT IN (B)").

expression_not_in_expression_list_test() ->         
    { not_in, _, _ } = get_ast("A NOT IN (A,B,C)").

expression_like_pattern_test() -> 
    { like, { property, "A" }, { string_constant, "TEXT" }} = get_ast("A LIKE 'TEXT'"),
    { like, { property, "A" }, { integer_constant, "123" }} = get_ast("A LIKE 123"),
    { like, { property, "A" }, { property, "B" }} = get_ast("A LIKE B"),
    { like, { property, "A" }, { subtraction, _, _ }} = get_ast("A LIKE B - C").

expression_like_pattern_escape_test() ->         
    { like, 
        _, 
        { string_constant, "TEXT\\%"}, 
        { escape, { string_constant, "\\" }}
    } = 
    get_ast("A LIKE 'TEXT\\%' ESCAPE '\\'").

expression_not_like_pattern_test() ->
    { not_like, _, _ } = get_ast("A NOT LIKE B").

expression_not_like_pattern_escape_test() -> 
    { not_like, _, _ , { escape, _ }} = get_ast("A NOT LIKE 'TEXT\\%' ESCAPE '\\'").

get_ast(String) ->
    { ok, Tokens, _ } = expression_lexer:string(String),
    { ok, AST } = expression_parser:parse(Tokens),
    AST.
