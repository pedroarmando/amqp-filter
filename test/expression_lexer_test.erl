-module(expression_lexer_test).
-include_lib("eunit/include/eunit.hrl").
-compile(nowarn_unused_function).

% EUnit Tests

regular_identifier_test() ->   
	{ regular_identifier, _, "m_property" } = get_token("m_property")
.

quoted_identifier_test() ->
	{ quoted_identifier, _, "Contoso & \"Northwind Traders\"" } = get_token("\"Contoso & \"\"Northwind Traders\"\"\"")
.

delimited_identifier_test() ->
	{ delimited_identifier, _, "Voici une [chaine] de [caracteres]" } = get_token("[Voici une [[chaine]] de [[caracteres]]]")
.

integer_constant_test() ->
	{ integer_constant, _, "1894" } = get_token("1894")
.

decimal_constant_test() ->
	{ decimal_constant, _, "1894.1204" } = get_token("1894.1204")
.

approximate_number_constant_test() ->
	{ approximate_number_constant, _, "042E1" } =    get_token("042E1"),
	{ approximate_number_constant, _, "042E-1" } =   get_token("042E-1"),
	{ approximate_number_constant, _, "042E+1" } =   get_token("042E+1"),
	{ approximate_number_constant, _, "042.0E1" } =  get_token("042.0E1"),
	{ approximate_number_constant, _, "042.0E-1" } = get_token("042.0E-1"),
	{ approximate_number_constant, _, "042.0E+1" } = get_token("042.0E+1")
.

boolean_constant_test() ->
	{ boolean_constant, _, "TRUE" } = get_token("TRUE")
.

string_constant_test() ->
	{ string_constant, _, "this is a 'valid' string constant" } = get_token("'this is a ''valid'' string constant'")
.

string_constant_invalid_quote_number_test() ->
	{ error, Tokens, _ } = expression_lexer:string("'this is an 'invalid string constant'"),
	{ _,_,{ illegal,[$' | _] }} = Tokens
.

null_constant_test() ->
	{ t_null, _, "NULL" } = get_token("NULL")
.

greater_than_operator_test() ->
	{ t_gt, _, ">" } = get_token(">")
.

greater_than_or_equal_operator_test() ->
	{ t_gte, _, ">=" } = get_token(">=")
.

less_than_operator_test() ->
	{ t_lt, _, "<" } = get_token("<")
.

less_than_or_equal_operator_test() ->
	{ t_lte, _, "<=" } = get_token("<=")
.

not_equal_operator_test() ->
	{ t_neq, _, "<>" } = get_token("<>")
.

not_equal_to_operator_test() ->
	{ t_neq, _, "!=" } = get_token("!=")
.

equal_operator_test() ->
	{ t_eq, _, "=" } = get_token("=")
.

is_operator_test() ->
	{ t_is, _, _ } = get_token("IS")
.

in_operator_test() ->
	{ t_in, _, "IN" } = get_token("IN")
.

like_operator_test() ->
	{ t_like, _, "LIKE" } = get_token("LIKE")
.

exists_operator_test() ->
	{ t_exists, _, _ } = get_token("EXISTS")
.

parentheses_test() -> 
	{ o_parentheses, _, "(" } = get_token("("),
	{ c_parentheses, _, ")" } = get_token(")")	
.

dot_test() ->
	{ t_dot, _, "." } = get_token(".")
.

comma_test() ->
	{ t_comma, _, "," } = get_token(",")
.

escape_clause_test() ->
	{ t_escape, _, "ESCAPE" } = get_token("ESCAPE")
.

logical_operators_test() ->
	{ t_not, _, "NOT" } = get_token("NOT"),
	{ t_and, _, "AND" } = get_token("AND"),
	{ t_or, _, "OR" } = get_token("OR")
.

arithmetic_operators_test() ->
	{ t_plus, _, "+" } = get_token("+"),
	{ t_minus, _, "-" } = get_token("-"),
	{ t_multiply, _, "*" } = get_token("*"),
	{ t_divide, _, "/" } = get_token("/"),
	{ t_percent, _, "%" } = get_token("%")
.

get_token(String) -> 
	{ ok, [Tokens], _ } = expression_lexer:string(String),
	Tokens
.