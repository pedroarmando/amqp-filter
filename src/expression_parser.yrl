Nonterminals 
    predicate
    expression
    expression_list
    property
    scope
    property_name
    constant
    pattern
    escape_char
.

Terminals   approximate_number_constant boolean_constant decimal_constant integer_constant string_constant
            delimited_identifier regular_identifier quoted_identifier
            t_eq t_neq t_gt t_gte t_lt t_lte t_like
            t_minus t_plus t_multiply t_divide t_percent
            c_parentheses o_parentheses 
            t_dot t_comma
            t_exists t_is t_in
            t_not t_and t_or
            t_null t_escape
.

Rootsymbol predicate.

Left 300 t_not.
Left 200 t_and.
Left 100 t_or.

Left 500 t_percent.
Left 400 t_multiply.
Left 300 t_divide.
Left 200 t_plus.
Left 100 t_minus.

predicate -> t_not predicate:               { not_op, '$2' }.
predicate -> predicate  t_and   predicate:  { and_op, '$1', '$3' }.
predicate -> predicate  t_or    predicate:  { or_op, '$1', '$3' }.
predicate -> expression t_eq    expression: { eq, '$1', '$3' }.
predicate -> expression t_neq   expression: { neq, '$1', '$3' }.
predicate -> expression t_gt    expression: { gt, '$1', '$3' }.
predicate -> expression t_gte   expression: { gte, '$1', '$3' }.
predicate -> expression t_lt    expression: { lt, '$1', '$3' }.
predicate -> expression t_lte   expression: { lte, '$1', '$3' }.

predicate -> property t_is t_null:          { is_null, '$1' }.
predicate -> property t_is t_not t_null:    { is_not_null, '$1' }.

predicate -> expression t_in        o_parentheses expression_list   c_parentheses: { in, '$1', '$4' }.
predicate -> expression t_not t_in  o_parentheses expression_list   c_parentheses: { not_in, '$1', '$5' }.

predicate -> expression t_like pattern:                         { like, '$1', '$3' }.
predicate -> expression t_like pattern t_escape escape_char:    { like, '$1', '$3', { escape, '$5' }}.

predicate -> expression t_not t_like pattern:                       { not_like, '$1', '$4' }.
predicate -> expression t_not t_like pattern t_escape escape_char:  { not_like, '$1', '$4', { escape, '$6' }}.

predicate -> t_exists o_parentheses property c_parentheses: { exists, '$3' }.

predicate -> o_parentheses predicate c_parentheses: '$2'.

expression -> constant: '$1'.
expression -> property: '$1'.
expression -> expression t_plus     expression: { addition, '$1', '$3' }.
expression -> expression t_minus    expression: { subtraction, '$1', '$3' }.
expression -> expression t_multiply expression: { multiplication, '$1', '$3' }.
expression -> expression t_divide   expression: { division, '$1', '$3' }.
expression -> expression t_percent  expression: { remainder, '$1', '$3' }.

expression -> t_plus    expression: { plus, '$2' }.
expression -> t_minus   expression: { minus, '$2' }.

expression -> o_parentheses expression c_parentheses: '$2'.

expression_list -> expression: ['$1'].
expression_list -> expression_list t_comma expression:  '$1' ++ ['$3'].

property -> property_name: { property, symbol_of('$1') }.
property -> scope t_dot property_name: { property, symbol_of('$3') }.

scope -> regular_identifier: '$1'.

property_name -> regular_identifier:    '$1'.
property_name -> quoted_identifier:     '$1'.
property_name -> delimited_identifier:  '$1'.

constant -> integer_constant:               { integer_constant, symbol_of('$1') }.
constant -> decimal_constant:               { decimal_constant, symbol_of('$1') }.
constant -> approximate_number_constant:    { approximate_number_constant, symbol_of('$1') }.
constant -> boolean_constant:               { boolean_constant, symbol_of('$1') }.
constant -> string_constant:                { string_constant, symbol_of('$1') }.

pattern -> expression: '$1'.
escape_char -> expression: '$1'.

Erlang code.

% Tokens produced by leex scanner are a tuple containing information
% about syntactic category, position in the input text and the actual
% terminal symbol found in the text:
% {Category, Position, Symbol}

symbol_of({ _, _, V }) -> V.