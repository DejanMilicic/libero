-module(cli_ffi).
-export([rpc/3, start_inets/0, int_to_string/1, list_each/2, parse_int/1, get_args/0]).

start_inets() ->
    application:ensure_all_started(inets),
    application:ensure_all_started(ssl),
    nil.

%% Encode a {Module, Msg} tuple as ETF, POST it, decode the response.
%% The server returns Result(MsgFromServer, RpcError) as ETF.
%% We unwrap the outer Ok/Error and the inner Ok/Error.
rpc(Url, Module, Msg) ->
    Payload = term_to_binary({Module, Msg}),
    UrlStr = binary_to_list(Url),
    case httpc:request(post, {UrlStr, [], "application/octet-stream", Payload}, [], [{body_format, binary}]) of
        {ok, {{_, 200, _}, _, Body}} ->
            case binary_to_term(Body) of
                {ok, Value} -> {ok, Value};
                {error, Reason} -> {error, format_error(Reason)}
            end;
        {ok, {{_, Code, _}, _, _}} ->
            {error, <<"HTTP error: ", (integer_to_binary(Code))/binary>>};
        {error, Reason} ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.

format_error(Err) ->
    list_to_binary(io_lib:format("~p", [Err])).

int_to_string(N) ->
    integer_to_binary(N).

list_each(List, Fun) ->
    lists:foreach(Fun, List),
    nil.

get_args() ->
    [list_to_binary(A) || A <- init:get_plain_arguments()].

parse_int(Bin) ->
    try
        {ok, binary_to_integer(Bin)}
    catch
        _:_ -> {error, nil}
    end.
