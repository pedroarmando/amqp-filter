-module(amqp_filter_test).
-include_lib("eunit/include/eunit.hrl").
-compile(nowarn_unused_function).

constant_comparison_test() ->
    true = amqp_filter:evaluate("2 = 2", []),
    true = amqp_filter:evaluate("2 <> 2.0", []),
    true = amqp_filter:evaluate("2 != 3", []),
    true = amqp_filter:evaluate("2 > 1", []),
    true = amqp_filter:evaluate("2 >= 1", []),
    true = amqp_filter:evaluate("2 < 3", []),
    true = amqp_filter:evaluate("2 <= 3", []),
    true = amqp_filter:evaluate("True = tRue", [])
.

predicate_between_parentheses_test() -> 
    true = amqp_filter:evaluate(" (2 = 2) ", [])
.

not_predicate_test() ->
    true = amqp_filter:evaluate("NOT 5 = 2", [])
.

and_predicate_test() -> 
    true = amqp_filter:evaluate("2 = 2 AND 3 = 3", []),
    false = amqp_filter:evaluate("2 = 2 AND 3 = 5", [])
.

or_predicate_test() -> 
    true = amqp_filter:evaluate("2 = 2 OR 3 = 5", [])
.

property_expression_test() ->
    Properties = [{ "PROP", "NICK" }],    
    true = amqp_filter:evaluate("PROP = 'NICK'", Properties),
    true = amqp_filter:evaluate("[PROP] = 'NICK'", Properties),
    true = amqp_filter:evaluate("\"PROP\" = 'NICK'", Properties)
.

property_types_test() ->
    true = amqp_filter:evaluate("PROP = '2'", [{ "PROP", "2" }]),
    true = amqp_filter:evaluate("PROP = 2", [{ "PROP", 2 }]),
    false = amqp_filter:evaluate("PROP = 2", [{ "PROP", "2" }]),
    true = amqp_filter:evaluate("PROP = 2", [{ "PROP", 2.0 }])
.

property_is_null_test() ->
    Properties = [{ "USERNAME", "NICK" }, { "PHONE", "NULL" }, { "ADDRESS", null }],
    
    false = amqp_filter:evaluate("USERNAME IS NULL", Properties),
    false = amqp_filter:evaluate("PHONE IS NULL", Properties),
    true = amqp_filter:evaluate("ADDRESS IS NULL", Properties),
    true  = amqp_filter:evaluate("NON_EXISTING_PROPERTY IS NULL", Properties)
.

property_is_not_null_test() ->
    Properties = [{ "USERNAME", "NICK" }], 
    true = amqp_filter:evaluate("USERNAME IS NOT NULL", Properties),
    false  = amqp_filter:evaluate("NON_EXISTING_PROPERTY IS NOT NULL", Properties)
.

expression_in_test() -> 
    true = amqp_filter:evaluate("2 IN (1, 2)", []),
    false = amqp_filter:evaluate("2 IN (1)", []),
    true = amqp_filter:evaluate("ID IN (1, 2)", [{ "ID", 2 }])
.

expression_not_in_test() -> 
    true = amqp_filter:evaluate("2 NOT IN (1, 3)", []),
    false = amqp_filter:evaluate("2 NOT IN (1, 2, 3)", [])
.

expression_like_test() -> 
    true = amqp_filter:evaluate("'NICK' LIKE 'NICK'", []),
    true = amqp_filter:evaluate("'NICK' LIKE 'nick'", []),
    true = amqp_filter:evaluate("'NICK' LIKE 'NI%'", []),
    true = amqp_filter:evaluate("'NICK' LIKE '%CK'", []),
    true = amqp_filter:evaluate("'NICK' LIKE 'NI__'", [])
.

expression_like_with_escape_test() ->
    true = amqp_filter:evaluate("'AB_CD' LIKE 'AB!_CD' ESCAPE '!'", []),
    true = amqp_filter:evaluate("'AB_CD' LIKE '%!_%' ESCAPE '!'", []),
    true = amqp_filter:evaluate("'AB_CD' LIKE 'A_!_C_' ESCAPE '!'", []),
    true = amqp_filter:evaluate("'50%' LIKE '50!%' ESCAPE '!'", []),
    true = amqp_filter:evaluate("'SALES:_REDUCTION=50%_' LIKE '%!_REDUCTION=__!%!_' ESCAPE '!'", []),
    true = amqp_filter:evaluate("'AAB_CD' LIKE '_AB\\_CD' ESCAPE '\\'", [])
.

expression_not_like_test() -> 
    false = amqp_filter:evaluate("'NICK' NOT LIKE 'NICK'", []),
    true = amqp_filter:evaluate("'NICK' NOT LIKE '_NICK'", [])    
.

expression_not_like_with_escape_test() -> 
    true = amqp_filter:evaluate("'NI_CK' NOT LIKE 'NIC\\_K' ESCAPE '\\'", [])    
.

escape_char_length_must_be_one_test_() ->
    ?_assertException(error, function_clause, amqp_filter:evaluate("'TEXT' LIKE 'PATTERN' ESCAPE '!!'", [])).

property_exist_test() ->
    true = amqp_filter:evaluate("EXISTS ( USERNAME )", [{ "USERNAME", "NICK" }]),
    false = amqp_filter:evaluate("EXISTS ( USERNAME )", [])    
.

arithmetic_operation_test() ->
    true = amqp_filter:evaluate("3 + 2 = 5", []),
    true = amqp_filter:evaluate("3 - 2 = 1", []),
    true = amqp_filter:evaluate("3 * 2 = 6", []),
    true = amqp_filter:evaluate("3 / 3 = 1", []),
    true = amqp_filter:evaluate("5 / 3 = 1", []), % Integer division
    true = amqp_filter:evaluate("5 % 2 = 1", [])  % Integer remainder 
.

signed_expression_test() ->
    true = amqp_filter:evaluate("2 - 5 = -3", []),
    true = amqp_filter:evaluate("5 - 2 = +3", [])
.

% If either the left and/or right side of operands is evaluated as unknown, 
% then the result is unknown.
unknown_comparison_operations_test() ->
    unknown = amqp_filter:evaluate("PROP = 5", []),    
    unknown = amqp_filter:evaluate("PROP > 5", []),
    unknown = amqp_filter:evaluate("PROP >= 5", []),
    unknown = amqp_filter:evaluate("PROP < 5", []),
    unknown = amqp_filter:evaluate("PROP <= 5", []),
    unknown = amqp_filter:evaluate("PROP <> 5", []),
    unknown = amqp_filter:evaluate("PROP != 5", [])
.

% If either the left and/or right side of operands is evaluated as unknown, 
% then the result is unknown.
unknown_arithmetic_operations_test() ->
    unknown = amqp_filter:evaluate("PROP + 5 = 5", []),
    unknown = amqp_filter:evaluate("PROP - 5 = 5", []),
    unknown = amqp_filter:evaluate("PROP * 5 = 5", []),
    unknown = amqp_filter:evaluate("PROP / 5 = 5", []),
    unknown = amqp_filter:evaluate("PROP % 5 = 5", []),
    unknown = amqp_filter:evaluate("-PROP = 5", []),
    unknown = amqp_filter:evaluate("+PROP = 5", [])
.

% If the left operand is evaluated as unknown, then the result is unknown.
unknown_not_in_expression_test() ->
    unknown = amqp_filter:evaluate("PROP IN (5)", []),
    unknown = amqp_filter:evaluate("PROP NOT IN (5)", []),
    false = amqp_filter:evaluate("5 IN (PROP)", []),
    true = amqp_filter:evaluate("5 NOT IN (PROP)", [])
.

% If any operand is evaluated as unknown, then the result is unknown.
unknown_like_expression_test() ->
    unknown = amqp_filter:evaluate("TEXT LIKE 'NICK'", []),
    unknown = amqp_filter:evaluate("'TEXT' LIKE PATTERN ESCAPE '!'", []),
    unknown = amqp_filter:evaluate("'TEXT' LIKE 'PATTERN' ESCAPE ESCAPE_CHAR", [])
.

%+---+---+---+---+  
%|AND| T | F | U |  
%+---+---+---+---+  
%| T | T | F | U |  
%+---+---+---+---+  
%| F | F | F | F |  
%+---+---+---+---+  
%| U | U | F | U |  
%+---+---+---+---+  
unknown_and_predicate_test() ->
    True_Expression = "5 = 5",
    False_Expression = "5 = 6",
    Unknown_Expression = "PROP = 5",
    unknown = amqp_filter:evaluate(True_Expression ++ " AND " ++ Unknown_Expression, []),
    false = amqp_filter:evaluate(False_Expression ++ " AND " ++ Unknown_Expression, []),
    unknown = amqp_filter:evaluate(Unknown_Expression ++ " AND " ++ Unknown_Expression, [])
.

%+---+---+---+---+  
%|OR | T | F | U |  
%+---+---+---+---+  
%| T | T | T | T |  
%+---+---+---+---+  
%| F | T | F | U |  
%+---+---+---+---+  
%| U | T | U | U |  
%+---+---+---+---+  
unknown_or_predicate_test() ->
    True_Expression = "5 = 5",
    False_Expression = "5 = 6",
    Unknown_Expression = "PROP = 5",
    true = amqp_filter:evaluate(True_Expression ++ " OR " ++ Unknown_Expression, []),
    unknown = amqp_filter:evaluate(False_Expression ++ " OR " ++ Unknown_Expression, []),
    unknown = amqp_filter:evaluate(Unknown_Expression ++ " OR " ++ Unknown_Expression, [])
.

predicate_with_illegal_token_must_fail_test() ->
    { error, _, _} = amqp_filter:evaluate("2 @ 2 = 4", []).    

predicate_with_sintax_error_must_fail_test() ->
    { error, _} = amqp_filter:evaluate("2 > NULL", [])
.