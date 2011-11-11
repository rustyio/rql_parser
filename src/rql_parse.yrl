%% -------------------------------------------------------------------
%%
%% Copyright (c) 2007-2010 Basho Technologies, Inc.  All Rights Reserved.
%%
%% -------------------------------------------------------------------

Nonterminals
query
where_step filter_step sort_step mapreduce_step slice_step 
clause terms dotted_fields sort_fields
.

Terminals
where
field eq gt lt term and or not to lparen rparen in comma dot between
filter 
map
reduce
sort asc desc
slice
.

Left 100 and.
Left 100 or.
Right 100 lparen.
Left 100 rparen.
Right 200 not.

Rootsymbol query.

%% The basic phases.
query -> where_step filter_step sort_step slice_step :
    Steps = [{where, '$1'}, {filter, '$2'}, {sort, '$3'}, {slice, '$4'}],
    [{X, Y} || {X, Y} <- Steps, Y /= undefined].
      
query -> where_step filter_step mapreduce_step :
    Steps = [{where, '$1'}, {filter, '$2'}, {mapreduce, keep_last_phase('$3')}],
    [{X, Y} || {X, Y} <- Steps, Y /= undefined].
    
where_step -> clause : 
    '$1'.

where_step -> where clause : 
    '$2'.

%% Filtering %%

filter_step -> '$empty' : 
    undefined.

filter_step -> filter clause :
    '$2'.

%% Sorting %% 

sort_step -> '$empty' : 
    undefined.

sort_step -> sort sort_fields :
    '$2'.

sort_fields -> field :
    [{val('$1'), asc}].

sort_fields -> field asc :
    [{val('$1'), asc}].

sort_fields -> field desc :
    [{val('$1'), desc}].

sort_fields -> field comma sort_fields :
    [{val('$1'), asc}] ++ '$3'.

sort_fields -> field asc comma sort_fields :
    [{val('$1'), asc}] ++ '$4'.

sort_fields -> field desc comma sort_fields :
    [{val('$1'), desc}] ++ '$4'.

%% Slicing %% 

slice_step -> '$empty' : undefined.
slice_step -> slice term to term :
    [list_to_integer(val('$2')), list_to_integer(val('$4'))].

%% MapReduce %%
   
mapreduce_step -> mapreduce_step map:
    '$1' ++ [transform_map(val('$2'))].

mapreduce_step -> map:
    [transform_map(val('$1'))].

mapreduce_step -> mapreduce_step reduce:
    '$1' ++ [transform_reduce(val('$2'))].

mapreduce_step -> reduce:
    [transform_reduce(val('$1'))].
 
%% Boolean Logic Clauses

clause -> field eq term :
       #function { field=val('$1'), function="=", args=[val('$3')] }.

clause -> field gt term :
       #function { field=val('$1'), function=">", args=[val('$3')] }.

clause -> field gt eq term :
       #function { field=val('$1'), function=">=", args=[val('$4')] }.

clause -> field lt term :
       #function { field=val('$1'), function="<", args=[val('$3')] }.

clause -> field lt eq term :
       #function { field=val('$1'), function="<=", args=[val('$4')] }.

clause -> field lt gt term :
       #negation { op=#function { field=val('$1'), function="=", args=[val('$4')] } }.

clause -> field between term and term :
       #function { field=val('$1'), function="between", args=[val('$3'), val('$5')] }.

clause -> lparen clause rparen :
       '$2'.

clause -> clause and clause :
       Ops = lists:flatten([unwrap(intersection, '$1'), unwrap(intersection, '$3')]),
       #intersection { ops=Ops }.

clause -> clause and not clause :
       Ops = lists:flatten([unwrap(intersection, '$1'), #negation { op=unwrap(intersection, '$3')}]),
       #intersection { ops=Ops }.

clause -> clause or clause :
       Ops = lists:flatten([unwrap(union, '$1'), unwrap(union, '$3')]),
       #union { ops=Ops }.

clause -> clause or not clause :
       Ops = lists:flatten([unwrap(union, '$1'), #negation { op=unwrap(union, '$3')}]),
       #union { ops=Ops }.

%% Field Functions

clause -> field dot field lparen rparen :
       #function { field=val('$1'), function=val('$3'), args=[] }.

clause -> field dot field lparen terms rparen :
       #function { field=val('$1'), function=val('$3'), args='$5' }.

clause -> dotted_fields dot field lparen rparen :
       #function { field='$1', function=val('$3'), args=[] }.

clause -> dotted_fields dot field lparen terms rparen :
       #function { field='$1', function=val('$3'), args='$5' }.

dotted_fields -> dotted_fields dot field:
       '$1' ++ "." ++ val('$3').

dotted_fields -> field dot field:
       val('$1') ++ "." ++ val('$3').

%% IN Statement
clause -> field in lparen terms rparen :
       #function { field=val('$1'), function="in", args='$4' }.

clause -> field in lparen rparen :
       #function { field=val('$1'), function="in", args=[] }.

terms -> term :
      [val('$1')].

terms -> terms comma term :
      '$1' ++ [val('$3')].

Erlang code.

-include("rql_parser.hrl").

val({_, _, V}) -> V.

unwrap(Type, [Rec]) ->
    unwrap(Type, Rec);
unwrap(intersection, Rec = #intersection {}) ->
    Rec#intersection.ops;
unwrap(union, Rec = #union {}) ->
    Rec#union.ops;
unwrap(_, Rec) ->
    Rec.

transform_map([_,_,_|S]) ->
    {map, {jsanon, list_to_binary("function " ++ S)}, undefined, false}.

transform_reduce([_,_,_,_,_,_|S]) ->
    {reduce, {jsanon, list_to_binary("function " ++ S)}, undefined, false}.
    
keep_last_phase(Phases) ->
    [{A,B,C,_}|T] = lists:reverse(Phases),
    lists:reverse([{A,B,C,true}|T]).