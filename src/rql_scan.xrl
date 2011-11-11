%% -------------------------------------------------------------------
%%
%% Copyright (c) 2007-2010 Basho Technologies, Inc.  All Rights Reserved.
%%
%% -------------------------------------------------------------------

Definitions.

%% Whitespace

WS       = [\b\f\n\r\t\s\v]+
COMMENT  = --.*
MAP      = [Mm][Aa][Pp]
REDUCE   = [Rr][Ee][Dd][Uu][Cc][Ee]
WHERE    = [Ww][Hh][Ee][Rr][Ee]
SLICE    = [Ss][Ll][Ii][Cc][Ee]
TO       = [Tt][Oo]
LTEQ     = \<\=
GTEQ     = \>\=
NEQ      = \<\>
LT       = \<
GT       = \>
EQ       = \=
END      = [Ee][Nn][Dd]
NOT      = [Nn][Oo][Tt]
AND      = [Aa][Nn][Dd]
OR       = [Oo][Rr]
IN       = [Ii][Nn]
BETWEEN  = [Bb][Ee][Tt][Ww][Ee][Ee][Nn]
SORT_BY  = [Ss][Oo][Rr][Tt]\s*[Bb][Yy]
ORDER_BY = [Oo][Rr][Dd][Ee][Rr]\s*[Bb][Yy]
ASC      = [Aa][Ss][Cc]
DESC     = [Dd][Ee][Ss][Cc]
FILTER   = [Ff][Ii][Ll][Tt][Ee][Rr]


% A single quoted string. Special characters are allowed in string.
SNGSTRING = '(\\'|[^'])*'

% A double quoted string. Special characters are allowed in string.
DBLSTRING = \"(\\\"|[^\"])*\"

% An integer.
NUMBER = (-?[0-9]+|-?[0-9]+\.[0-9]+)

% An unquoted string. 
% Must not start with a special character.  
% Must not contain unescaped special characters.
STRING = [a-zA-Z0-9_]*

Rules.
{MAP}(.|\n)*    : 
    {Chars, Pushback} = peel_mapreduce(TokenChars), 
    {token, {map, TokenLine, Chars}, Pushback}.
{REDUCE}(.|\n)*    : 
    {Chars, Pushback} = peel_mapreduce(TokenChars), 
    {token, {reduce, TokenLine, Chars}, Pushback}.
{WHERE}     : skip_token.
\(          : {token, {lparen, TokenLine, TokenChars}}.
\)          : {token, {rparen, TokenLine, TokenChars}}.
\,          : {token, {comma, TokenLine, TokenChars}}.
\.          : {token, {dot, TokenLine, TokenChars}}.
{FILTER}    : {token, {filter, TokenLine, TokenChars}}.
{REDUCE}    : {token, {map, TokenLine, TokenChars}}.
{SORT_BY}   : {token, {sort, TokenLine, TokenChars}}.
{ORDER_BY}  : {token, {sort, TokenLine, TokenChars}}.
{SLICE}     : {token, {slice, TokenLine, TokenChars}}.
{LT}        : {token, {lt, TokenLine, TokenChars}}.
{GT}        : {token, {gt, TokenLine, TokenChars}}.
{EQ}        : {token, {eq, TokenLine, TokenChars}}.
{NOT}       : {token, {'not', TokenLine, TokenChars}}.
{AND}       : {token, {'and', TokenLine, TokenChars}}.
{OR}        : {token, {'or', TokenLine, TokenChars}}.
{IN}        : {token, {in, TokenLine, TokenChars}}.
{BETWEEN}   : {token, {between, TokenLine, TokenChars}}.
{TO}        : {token, {to, TokenLine, TokenChars}}.
{ASC}       : {token, {asc, TokenLine, TokenChars}}.
{DESC}      : {token, {desc, TokenLine, TokenChars}}.
{NUMBER}    : {token, {term, TokenLine, TokenChars}}.
{DBLSTRING} : {token, {field, TokenLine, unescape(strip(TokenChars))}}.
{SNGSTRING} : {token, {term, TokenLine, unescape(strip(TokenChars))}}.
{STRING}    : {token, {field, TokenLine, unescape(TokenChars)}}.
{WS}        : skip_token.
{COMMENT}   : skip_token.
.           : parse_error(TokenLine, TokenChars).

Erlang code.

-include("rql_parser.hrl").

%% Strip the first and last char, which will be quotes. Unescape anything else.
strip(S) ->
    lists:sublist(S, 2, length(S) - 2).

%% Unescape any escaped chars *except* for '*' and '?'.
unescape(S) ->
    unescape(S, []).
unescape([$\\,C|Rest], Acc) when C/=$* andalso C/=$? ->
    unescape(Rest, [C|Acc]);
unescape([C|Rest], Acc) ->
    unescape(Rest, [C|Acc]);
unescape([], Acc) ->
    lists:reverse(Acc).

peel_mapreduce(TokenChars) ->
    case re:run(TokenChars, "\n\s*(--|map|reduce)", [caseless, multiline, {capture, all_but_first}]) of
        {match, [{Start, _}]} ->
            lists:split(Start, TokenChars);
        _Other ->
            {TokenChars, ""}
    end.

parse_error(TokenLine, TokenChars) ->
    io:format("Invalid character \"~s\" at line ~s", [TokenChars, TokenLine]),
    {error, lists:flatten(io_lib:format("invalid character \"~s\" at line ~s", [TokenChars, TokenLine]))}.