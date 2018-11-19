Definitions.

WS = [\s\t\r\n]

REGULAR_IDENTIFIER = [a-zA-Z][_a-zA-Z0-9]*
QUOTED_IDENTIFIER = \"([^\"]|\"\")*\"
DELIMITED_IDENTIFIER = \[([^\[\]]|\[\[|\]\])+\]

INTEGER_CONSTANT = [0-9]+
DECIMAL_CONSTANT = [0-9]+\.[0-9]+
NUMBER_CONSTANT = [0-9]+(\.[0-9]+)?[eE][-+]?[0-9]+
BOOLEAN_CONSTANT = ([tT][rR][uU][eE])|([fF][aA][lL][sS][eE])
STRING_CONSTANT = '([^']|'')*'

ESCAPE = [eE][sS][cC][aA][pP][eE]

NOT = [nN][oO][tT]
AND = [aA][nN][dD]
OR = [oO][rR]

EQ = =
NEQ = <>
NEQ2 = !=
GT = >
GTE = >=
LT = <
LTE = <=

EXISTS = [eE][xX][iI][sS][tT][sS]

IS = [iI][sS]
IN = [iI][nN]
LIKE = [lL][iI][kK][eE]
NULL = [nN][uU][lL][lL]

O_PARENTHESES = \(
C_PARENTHESES = \)
DOT = \.
COMMA = ,
PLUS = \+
MINUS = -
MULTIPLY = \*
DIVIDE = \/
PERCENT = %

Rules.

{WS} : skip_token.

{NULL} : t(t_null, TokenLine, TokenChars).

{EQ} : t(t_eq, TokenLine, TokenChars).
{NEQ} : t(t_neq, TokenLine, TokenChars).
{NEQ2} : t(t_neq, TokenLine, TokenChars).
{GT} : t(t_gt, TokenLine, TokenChars).
{GTE} : t(t_gte, TokenLine, TokenChars).
{LT} : t(t_lt, TokenLine, TokenChars).
{LTE} : t(t_lte, TokenLine, TokenChars).

{IS} : t(t_is, TokenLine, TokenChars).
{IN} : t(t_in, TokenLine, TokenChars).
{LIKE} : t(t_like, TokenLine, TokenChars).
{EXISTS} : t(t_exists, TokenLine, TokenChars).

{O_PARENTHESES} : t(o_parentheses, TokenLine, TokenChars).
{C_PARENTHESES} : t(c_parentheses, TokenLine, TokenChars).

{DOT} : t(t_dot, TokenLine, TokenChars).
{COMMA} : t(t_comma, TokenLine, TokenChars).

{PLUS} : t(t_plus, TokenLine, TokenChars).
{MINUS} : t(t_minus, TokenLine, TokenChars).
{MULTIPLY} : t(t_multiply, TokenLine, TokenChars).
{DIVIDE} : t(t_divide, TokenLine, TokenChars).
{PERCENT} : t(t_percent, TokenLine, TokenChars).

{ESCAPE} : t(t_escape, TokenLine, TokenChars).

{NOT} : t(t_not, TokenLine, TokenChars).
{AND} : t(t_and, TokenLine, TokenChars).
{OR} : t(t_or, TokenLine, TokenChars).

{INTEGER_CONSTANT} : t(integer_constant, TokenLine, TokenChars).
{DECIMAL_CONSTANT} : t(decimal_constant, TokenLine, TokenChars).
{NUMBER_CONSTANT} : t(approximate_number_constant, TokenLine, TokenChars).
{BOOLEAN_CONSTANT} : t(boolean_constant, TokenLine, TokenChars).
{STRING_CONSTANT} : t(string_constant, TokenLine, unquote_string_constant(TokenChars)).

{REGULAR_IDENTIFIER} : t(regular_identifier, TokenLine, TokenChars).
{QUOTED_IDENTIFIER} : t(quoted_identifier, TokenLine, unquote_quoted_identifier(TokenChars)).
{DELIMITED_IDENTIFIER} : t(delimited_identifier, TokenLine, unquote_delimited_identifier(TokenChars)).

Erlang code.

t(TokenType, TokenLine, TokenChars) -> { token, {TokenType, TokenLine, TokenChars } }.

unquote_delimited_identifier(Identifier) ->
    Len = string:len(Identifier),
    Text = string:substr(Identifier, 2, Len - 2),
    re:replace(
        re:replace(Text, "\\[\\[", "[", [global, { return, list }]),  
        "\\]\\]", 
        "]", 
        [global, { return, list }])
.

unquote_quoted_identifier(Identifier) ->
    Len = string:len(Identifier),
    Text = string:substr(Identifier, 2, Len - 2),
    re:replace(Text, "\"\"", "\"", [global, { return, list }])
.

unquote_string_constant(String) ->
    Len = string:len(String),
    Text = string:substr(String, 2, Len - 2),
    re:replace(Text, "''", "'", [global, { return, list }])    
.