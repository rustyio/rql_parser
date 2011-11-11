%% -------------------------------------------------------------------
%%
%% Copyright (c) 2007-2010 Basho Technologies, Inc.  All Rights Reserved.
%%
%% -------------------------------------------------------------------

-module(rql_parser).
-export([parse/1]).
-include("rql_parser.hrl").

%% @doc Parse a given query string into a query graph. The query graph
%% consists of a nested set of Erlang records found in rql_parser.hrl.
parse(QueryString) when is_list(QueryString) ->
    case rql_scan:string(QueryString) of
        {ok, Tokens, _} -> 
            case rql_parse:parse(Tokens) of
                {ok, QueryOps} -> 
                    %% Success case.
                    {ok, QueryOps};
                {error, {_, rql_parse, String}} ->
                    %% Syntax error.
                    {error, {rql_parse, lists:flatten(String)}};
                {error, Error} -> 
                    %% Other parsing error.
                    {error, Error}
            end;
        {error, Error} ->
            %% Scanning error.
            {error, Error}
    end.


