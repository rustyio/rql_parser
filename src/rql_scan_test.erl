%% -------------------------------------------------------------------
%%
%% Copyright (c) 2007-2010 Basho Technologies, Inc.  All Rights Reserved.
%%
%% -------------------------------------------------------------------

-module(rql_scan_test).
-include_lib("eunit/include/eunit.hrl").

field1_test() ->
    Expect = [
        {field, 1, "field"},
        {eq, 1, "="},
        {term, 1, "value"}
    ],
    test_helper("field='value'", Expect),
    test_helper("field ='value'", Expect),
    test_helper("field= 'value'", Expect),
    test_helper("field = 'value'", Expect),
    test_helper("\"field\"='value'", Expect).

field2_test() ->
    Expect = [
        {field, 1, "field"},
        {eq, 1, "="},
        {term, 1, "1"}
    ],
    test_helper("field=1", Expect),
    test_helper("field =1", Expect),
    test_helper("field= 1", Expect),
    test_helper("field = 1", Expect),
    test_helper("\"field\"=1", Expect).

field3_test() ->
    Expect = [
        {field, 1, "field"},
        {eq, 1, "="},
        {term, 1, "-1"}
    ],
    test_helper("field=-1", Expect),
    test_helper("field =-1", Expect),
    test_helper("field= -1", Expect),
    test_helper("field = -1", Expect),
    test_helper("\"field\"=-1", Expect).

field4_test() ->
    Expect = [
        {field, 1, "!@#$%^&*()[{}]-_ field"},
        {eq, 1, "="},
        {term, 1, "!@#$%^&*()[{}]-_ value"}
    ],
    test_helper("\"!@#$%^&*()[{}]-_ field\"='!@#$%^&*()[{}]-_ value'", Expect).

and1_test() ->
    Expect = [
        {field,1,"field1"},
        {eq,1,"="},
        {term,1,"1"},
        {'and',1,"AND"},
        {field,1,"field2"},
        {eq,1,"="},
        {term,1,"2"}
    ],
    test_helper("field1 = 1 AND field2 = 2", Expect).

and2_test() ->
    Expect = [
        {lparen,1,"("},
        {field,1,"field1"},
        {eq,1,"="},
        {term,1,"1"},
        {'and',1,"AND"},
        {field,1,"field2"},
        {eq,1,"="},
        {term,1,"2"},
        {rparen,1,")"}
    ],
    test_helper("(field1 = 1 AND field2 = 2)", Expect).

or1_test() ->
    Expect = [
        {field,1,"field1"},
        {eq,1,"="},
        {term,1,"1"},
        {'or',1,"OR"},
        {field,1,"field2"},
        {eq,1,"="},
        {term,1,"2"}
    ],
    test_helper("field1 = 1 OR field2 = 2", Expect).

or2_test() ->
    Expect = [
        {lparen,1,"("},
        {field,1,"field1"},
        {eq,1,"="},
        {term,1,"1"},
        {'or',1,"OR"},
        {field,1,"field2"},
        {eq,1,"="},
        {term,1,"2"},
        {rparen,1,")"}
    ],
    test_helper("(field1 = 1 OR field2 = 2)", Expect).
    
group1_test() ->
    Expect = [
        {lparen, 1, "("},
        {field, 1, "field"},
        {eq, 1, "="},
        {term, 1, "value"},
        {rparen, 1, ")"}
    ],
    test_helper("(field='value')", Expect),
    test_helper("(field ='value')", Expect),
    test_helper("(field= 'value')", Expect),
    test_helper("(field = 'value')", Expect),
    test_helper("(\"field\"='value')", Expect).

in1_test() ->
    Expect = [
        {field, 1, "field"},
        {in, 1, "in"},
        {lparen, 1, "("},
        {term, 1, "1"},
        {comma, 1, ","},
        {term, 1, "2"},
        {comma, 1, ","},
        {term, 1, "3"},
        {rparen, 1, ")"}
    ],
    test_helper("field in (1, 2, 3)", Expect).

between1_test() ->
    Expect = [
        {field, 1, "field"},
        {between, 1, "between"},
        {term, 1, "1"},
        {'and', 1, "and"},
        {term, 1, "3"}
    ],
    test_helper("field between 1 and 3", Expect).

fieldfunction1_test() ->
    Expect = [
        {field, 1, "field"},
        {dot, 1, "."},
        {field, 1, "equals"},
        {lparen, 1, "("},
        {term, 1, "1"},
        {rparen, 1, ")"}
    ],
    test_helper("field.equals(1)", Expect).

%% map1_test() ->
%%     Expect = [],
%%     test_helper("
%%         WHERE field1=1
%%         MAP(blah, blah) {
%%             if(true) {
%%               return true;
%%             } else {
%%               return false;
%%             }
%%         }
%%         REDUCE(blah3, blah3) {
%%            return [];
%%         }
%%         MAP(blah2, blah2) {
%%            // this is a fun test.
%%            return blah2;
%%         }", Expect).

test_helper(String, Expect) ->
    {ok, Actual, _} = rql_scan:string(String),
    Actual == Expect orelse throw({error, String, Actual, Expect}).

