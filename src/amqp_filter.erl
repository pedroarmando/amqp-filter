%% @doc This module provides the `evaluate' function that allow to evaluate the predicates.

-module(amqp_filter).

%% API exports
-export([evaluate/2]).

%%====================================================================
%% API functions

%% @doc Evaluates a SQL92 predicate based on a property collection. The predicate and property collection must follow 
%% <a href="https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-sql-filter" target="_blank">this BNF grammar specifications</a>.
%% 
%% <strong>Example: predicate successfully evaluated</strong>
%% ```
%% amqp_filter:evaluate("ID IN (123, 456, 789)", [{"ID", 456}]).
%% true
%% amqp_filter:evaluate("USERNAME = 'NICK' AND AGE > 18", [{ "USERNAME", "NICK" }, { "AGE", 25 }]).
%% true
%% amqp_filter:evaluate("YEAR % 4 = 0 AND (NOT YEAR % 100 = 0 OR YEAR % 400 = 0)", [{ "YEAR", 2018 }]).
%% false
%% '''
%%
%% <strong>Example: non-existent user property</strong> 
%% (<a href="https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-sql-filter#property-evaluation-semantics" target="_blank">more details</a>)
%% ```
%% amqp_filter:evaluate("USERNAME = 'NICK'", []).
%% unknown
%% '''
%%
%% <strong>Example: lexer or parser error</strong>
%% ```
%% amqp_filter:evaluate("2 @ (1, 2, 3)", []).
%% {error,{1,expression_lexer,{illegal,"@"}},1}
%%
%% amqp_filter:evaluate("2 IN (1,)", []).
%% {error,{1,expression_parser, ["syntax error before: ",["\")\""]]}}
%% '''

-spec evaluate(Predicate, Properties) -> boolean() | unknown | { error, Message } when
        Predicate :: string(),
        Properties :: [{Key, Value}],
        Key :: term(),
        Value :: term(),
        Message :: term().

evaluate(Predicate, Properties) when is_list(Properties) ->
    case expression_lexer:string(Predicate) of
        { ok, Tokens, _ } ->
            case expression_parser:parse(Tokens) of
                { ok, AST } ->
                    (make_predicate_evaluator(AST))(Properties);
                Error -> 
                    Error
            end;
        Error ->
            Error
    end.
%%====================================================================


%%====================================================================
%% Internal functions
make_predicate_evaluator({ not_op, Predicate }) -> make_not_evaluator(make_predicate_evaluator(Predicate));
make_predicate_evaluator({ and_op, LeftPredicate, RightPredicate }) -> 
    make_and_evaluator(
        make_predicate_evaluator(LeftPredicate), 
        make_predicate_evaluator(RightPredicate));
make_predicate_evaluator({ or_op, LeftPredicate, RightPredicate }) -> 
        make_or_evaluator(
            make_predicate_evaluator(LeftPredicate), 
            make_predicate_evaluator(RightPredicate));
make_predicate_evaluator({ Op = eq, LeftExpression, RightExpression }) -> make_comparison_evaluator(Op, LeftExpression, RightExpression);
make_predicate_evaluator({ Op = neq, LeftExpression, RightExpression }) -> make_comparison_evaluator(Op, LeftExpression, RightExpression);
make_predicate_evaluator({ Op = gt, LeftExpression, RightExpression }) -> make_comparison_evaluator(Op, LeftExpression, RightExpression);
make_predicate_evaluator({ Op = gte, LeftExpression, RightExpression }) -> make_comparison_evaluator(Op, LeftExpression, RightExpression);
make_predicate_evaluator({ Op = lt, LeftExpression, RightExpression }) -> make_comparison_evaluator(Op, LeftExpression, RightExpression);
make_predicate_evaluator({ Op = lte, LeftExpression, RightExpression }) -> make_comparison_evaluator(Op, LeftExpression, RightExpression);
make_predicate_evaluator({ is_null, Property }) -> make_is_null_evaluator(make_expression_evaluator(Property));
make_predicate_evaluator({ is_not_null, Property }) -> make_is_not_null_evaluator(make_expression_evaluator(Property));
make_predicate_evaluator({ in, LeftExpression, ExpressionList }) -> 
        make_in_evaluator(
            make_expression_evaluator(LeftExpression),
            make_expression_evaluator(ExpressionList));
make_predicate_evaluator({ not_in, LeftExpression, ExpressionList }) -> 
        make_not_in_evaluator(
            make_expression_evaluator(LeftExpression),
            make_expression_evaluator(ExpressionList));
make_predicate_evaluator({ like, LeftExpression, PatternExpression }) -> 
    make_like_evaluator(
            make_expression_evaluator(LeftExpression),
            make_expression_evaluator(PatternExpression));
make_predicate_evaluator({ like, LeftExpression, PatternExpression, { escape, EscapeChar} }) -> 
        make_like_escape_evaluator(
                make_expression_evaluator(LeftExpression),
                make_expression_evaluator(PatternExpression),
                make_expression_evaluator(EscapeChar));
make_predicate_evaluator({ not_like, LeftExpression, PatternExpression }) -> 
    make_not_like_evaluator(
           make_expression_evaluator(LeftExpression),
            make_expression_evaluator(PatternExpression));
make_predicate_evaluator({ not_like, LeftExpression, PatternExpression, { escape, EscapeChar} }) -> 
    make_not_like_escape_evaluator(
            make_expression_evaluator(LeftExpression),
            make_expression_evaluator(PatternExpression),
            make_expression_evaluator(EscapeChar));
make_predicate_evaluator({ exists, Property }) -> make_exist_evaluator(make_expression_evaluator(Property)).

    
make_comparison_evaluator(Operator, LeftExpression, RightExpression) ->
    Associations = dict:from_list([
            { eq, fun make_equal_evaluator/2 },
            { neq, fun make_not_equal_evaluator/2 },
            { gt, fun make_greater_than_evaluator/2 },
            { gte, fun make_greater_than_equal_evaluator/2 },
            { lt, fun make_less_than_evaluator/2 },
            { lte, fun make_less_than_equal_evaluator/2 }
        ]),
            
    LeftEvaluator = make_expression_evaluator(LeftExpression),
    RightEvaluator = make_expression_evaluator(RightExpression),

    Func = dict:fetch(Operator, Associations),
    Func(LeftEvaluator, RightEvaluator)
.

make_not_evaluator(Evaluator) ->
    fun(Properties) ->
        not Evaluator(Properties)
    end.

make_and_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) ->
        LeftValue = LeftEvaluator(Properties),
        RightValue = RightEvaluator(Properties),
        case at_least_one_unknown([LeftValue, RightValue]) of
            false -> LeftValue and RightValue;
            _ -> case (LeftValue == false) or (RightValue == false) of
                    true -> false;
                    _ -> unknown
                end   
        end
    end.

make_or_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) ->
            LeftValue = LeftEvaluator(Properties),
            RightValue = RightEvaluator(Properties),
            case at_least_one_unknown([LeftValue, RightValue]) of
                false -> LeftValue or RightValue;
                _ -> case (LeftValue == true) or (RightValue == true) of
                        true -> true;
                        _ -> unknown
                    end   
            end
        end.


make_equal_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) ->
        LeftValue = LeftEvaluator(Properties),
        RightValue = RightEvaluator(Properties),
        case at_least_one_unknown([LeftValue, RightValue]) of
            true -> unknown;
            _ -> LeftValue == RightValue
        end
    end.

make_not_equal_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) ->
        LeftValue = LeftEvaluator(Properties),
        RightValue = RightEvaluator(Properties),
        case at_least_one_unknown([LeftValue, RightValue]) of
            true -> unknown;
            _ -> LeftValue =/= RightValue         
        end
    end.

make_greater_than_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) ->
        LeftValue = LeftEvaluator(Properties),
        RightValue = RightEvaluator(Properties),
        case at_least_one_unknown([LeftValue, RightValue]) of
            true -> unknown;
            _ -> LeftValue > RightValue              
        end
    end.

make_greater_than_equal_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) ->
            LeftValue = LeftEvaluator(Properties),
            RightValue = RightEvaluator(Properties),
            case at_least_one_unknown([LeftValue, RightValue]) of
                true -> unknown;
                _ -> LeftValue >= RightValue                
            end
        end.

make_less_than_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) ->
            LeftValue = LeftEvaluator(Properties),
            RightValue = RightEvaluator(Properties),
            case at_least_one_unknown([LeftValue, RightValue]) of
                true -> unknown;
                _ -> LeftValue < RightValue                
            end
        end.

make_less_than_equal_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) ->
            LeftValue = LeftEvaluator(Properties),
            RightValue = RightEvaluator(Properties),
            case at_least_one_unknown([LeftValue, RightValue]) of
                true -> unknown;
                _ -> LeftValue =< RightValue                
            end
        end.

make_is_null_evaluator(Evaluator) ->
        fun(Properties) ->
            Value = Evaluator(Properties),
            case Value of
                unknown -> true;
                _ -> Value == null
            end
        end.  

make_is_not_null_evaluator(Evaluator) ->
    fun(Properties) ->
        Value = Evaluator(Properties),
        case Value of
            unknown -> false;
            _ -> Value /= null
        end
    end. 

make_in_evaluator(LeftEvaluator, EvaluatorList) ->
    fun(Properties) ->
        Value = LeftEvaluator(Properties),
        case at_least_one_unknown([Value]) of
            true -> unknown;
            _ -> 
                List = lists:foldl(fun(Evaluator, Acc) -> [Evaluator(Properties)] ++ Acc end, [], EvaluatorList),
                lists:any(fun(Item) -> Item == Value end, List)
        end        
    end.

make_not_in_evaluator(LeftEvaluator, EvaluatorList) ->
    fun(Properties) ->
        Value = LeftEvaluator(Properties),
        case at_least_one_unknown([Value]) of
            true -> unknown;
            _ -> 
                List = lists:foldl(fun(Evaluator, Acc) -> [Evaluator(Properties)] ++ Acc end, [], EvaluatorList),
                lists:all(fun(Item) -> Item /= Value end, List)                
        end        
    end.

make_like_evaluator(ExpressionEvaluator, PatternEvaluator) -> 
    fun(Properties) ->
        is_match(ExpressionEvaluator(Properties), PatternEvaluator(Properties))
    end.

make_like_escape_evaluator(ExpressionEvaluator, PatternEvaluator, EscapeCharEvaluator) -> 
        fun(Properties) ->
            is_match(ExpressionEvaluator(Properties), PatternEvaluator(Properties), EscapeCharEvaluator(Properties))
        end.

make_not_like_evaluator(ExpressionEvaluator, PatternEvaluator) -> 
    fun(Properties) ->
        not is_match(ExpressionEvaluator(Properties), PatternEvaluator(Properties))
    end.   

make_not_like_escape_evaluator(ExpressionEvaluator, PatternEvaluator, EscapeCharEvaluator) -> 
    fun(Properties) ->
        not is_match(ExpressionEvaluator(Properties), PatternEvaluator(Properties), EscapeCharEvaluator(Properties))
    end. 

make_exist_evaluator(ExpressionEvaluator) ->
    fun(Properties) ->
        case ExpressionEvaluator(Properties) of
            unknown -> false;
            _ -> true                
        end
    end.


make_expression_evaluator({ integer_constant, String }) -> make_integer_evaluator(String);
make_expression_evaluator({ decimal_constant, String }) -> make_decimal_evaluator(String);
make_expression_evaluator({ boolean_constant, String }) -> make_boolean_evaluator(String);
make_expression_evaluator({ string_constant, String }) -> make_string_evaluator(String);

make_expression_evaluator({ property, String }) -> make_property_evaluator(String);

make_expression_evaluator({ plus, Expression }) -> make_expression_evaluator(Expression);
make_expression_evaluator({ minus, Expression }) -> make_negation_evaluator(make_expression_evaluator(Expression));

make_expression_evaluator({ addition, LeftExpression, RightExpression}) ->
    make_addition_evaluator(
        make_expression_evaluator(LeftExpression),
        make_expression_evaluator(RightExpression)
    );
make_expression_evaluator({ subtraction, LeftExpression, RightExpression}) ->
    make_subtraction_evaluator(
        make_expression_evaluator(LeftExpression),
        make_expression_evaluator(RightExpression)
    );
make_expression_evaluator({ multiplication, LeftExpression, RightExpression}) ->
    make_multiplication_evaluator(
        make_expression_evaluator(LeftExpression),
        make_expression_evaluator(RightExpression)
    );
make_expression_evaluator({ division, LeftExpression, RightExpression}) ->
    make_division_evaluator(
        make_expression_evaluator(LeftExpression),
        make_expression_evaluator(RightExpression)
    );
make_expression_evaluator({ remainder, LeftExpression, RightExpression}) ->
    make_remainder_evaluator(
        make_expression_evaluator(LeftExpression),
        make_expression_evaluator(RightExpression)
    );
make_expression_evaluator([Expression|T]) -> [make_expression_evaluator(Expression)] ++ make_expression_evaluator(T);
make_expression_evaluator([]) -> [].


make_integer_evaluator(String) ->
    fun(_) ->
        { V, _ } = string:to_integer(String),
        V
    end.

make_decimal_evaluator(String) ->
    fun(_) ->
        { V, _ } = string:to_float(String),
        V
    end.

make_boolean_evaluator(String) ->
    fun(_) ->
        string:equal(String, "true", true)
    end.

make_string_evaluator(String) ->
    fun(_) ->
        String
    end.

make_property_evaluator(Key) ->
    fun(Properties) ->
        Value = proplists:get_value(Key, Properties),
        case Value of
                undefined -> unknown;
                _ -> Value
        end
    end.

make_negation_evaluator(Evaluator) ->
    fun(Properties) ->
        Value = Evaluator(Properties),
        case at_least_one_unknown([Value]) of
            true -> unknown;
            _ -> -1 * Value        
        end        
    end.

make_addition_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) -> 
        LeftValue = LeftEvaluator(Properties),
        RightValue = RightEvaluator(Properties),
        case at_least_one_unknown([LeftValue, RightValue]) of
            true -> unknown;
            _ -> LeftValue + RightValue                
        end
    end.

make_subtraction_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) -> 
        LeftValue = LeftEvaluator(Properties),
        RightValue = RightEvaluator(Properties),
        case at_least_one_unknown([LeftValue, RightValue]) of
            true -> unknown;
            _ -> LeftValue - RightValue                
        end
    end.

make_multiplication_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) -> 
        LeftValue = LeftEvaluator(Properties),
        RightValue = RightEvaluator(Properties),
        case at_least_one_unknown([LeftValue, RightValue]) of
            true -> unknown;
            _ -> LeftValue * RightValue                
        end
    end.

make_division_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) -> 
        LeftValue = LeftEvaluator(Properties),
        RightValue = RightEvaluator(Properties),
        case at_least_one_unknown([LeftValue, RightValue]) of
            true -> unknown;
            _ -> LeftValue div RightValue                
        end
    end.

make_remainder_evaluator(LeftEvaluator, RightEvaluator) ->
    fun(Properties) -> 
        LeftValue = LeftEvaluator(Properties),
        RightValue = RightEvaluator(Properties),
        case at_least_one_unknown([LeftValue, RightValue]) of
            true -> unknown;
            _ -> LeftValue rem RightValue                
        end
    end.

is_match(String, Pattern) -> is_match(String, Pattern, []).

is_match(String, Pattern, EscapeChar) when String == unknown orelse Pattern == unknown orelse EscapeChar == unknown -> unknown;
is_match(String, Pattern, EscapeChar) ->
    Regex = get_like_regex_expression(Pattern, EscapeChar),
    case re:run(String, Regex) of
        nomatch -> false;
        _ -> true            
    end.

get_like_regex_expression(Pattern, EscapeChar) ->
    Regex = get_regex(Pattern, EscapeChar),
    { ok, Caseless_Regex } = re:compile("^" ++ Regex ++ "$", [caseless]),
    Caseless_Regex
.

get_regex(Pattern, []) -> apply_wildcards(Pattern);
get_regex(Pattern, Escape) when length(Escape) =< 1 ->
    Escape_Char = escape_if_metacharacter(Escape),
    Escape_Percent = Escape_Char ++ "%",
    Escape_Underscore = Escape_Char ++ "_",
    Split = re:split(
                    Pattern, 
                    "(" ++ Escape_Percent ++ "|" ++ Escape_Underscore ++ ")", 
                    [{ return, list }, group]),
    Escaped_Pattern = lists:foldl(
                        fun(Split_Item, Acc) -> Acc ++ escape(Split_Item) end, 
                        [], 
                        Split),
    Escaped_Pattern.

escape_if_metacharacter(Char) ->
    Metacharacters = ["\\", "|", "[", "]", "(", ")", "?", "*", "+", "$", "^"],
    case lists:any(fun(Item) -> Item == Char end, Metacharacters) of
        true -> "\\" ++ Char;
        _ -> Char
    end.

escape(Split_Item) ->
    case Split_Item of
        [Part, [_, WildCard]] -> lists:flatten(string:concat([apply_wildcards(Part)], [WildCard]));
        [Part] -> apply_wildcards(Part)
    end.

apply_wildcards(String) ->
    re:replace(
        re:replace(String, "%", ".*", [global, { return, list }]),
        "_",
        ".",
        [global, { return, list }]).

at_least_one_unknown(Values) when is_list(Values) -> 
    lists:any(fun(Value) -> Value == unknown end, Values).

%%====================================================================
