-ifndef(PRINT).
-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).
-endif.

-record(function, {
    field,
    function,
    args
}).

-record(intersection, {
    ops
}).

-record(union, {
    ops
}).

-record(negation, {
    op
}).

-record (group, {
    ops
}).
