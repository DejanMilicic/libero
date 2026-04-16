-module(cli_ffi).
-export([rpc/3, start_inets/0, int_to_string/1, list_each/2, parse_int/1, get_args/0]).

start_inets() ->
    application:ensure_all_started(inets),
    application:ensure_all_started(ssl),
    nil.

%% Encode a {Module, Msg} tuple as ETF, POST it, decode the response.
%%
%% After libero's dispatch-side envelope unwrap, the wire response is
%%   `Result(Result(payload, domain_err), RpcError(app_err))` -
%% i.e. two nested Results. The outer Result is libero's framework
%% layer; the inner Result is whatever the MsgFromServer variant
%% carried (always Result-typed by convention).
%%
%% This helper collapses both layers into a flat `Result(payload, String)`
%% so the calling code only has to switch on success vs. failure with
%% a pre-formatted error message.
rpc(Url, Module, Msg) ->
    Payload = term_to_binary({Module, Msg}),
    UrlStr = binary_to_list(Url),
    case httpc:request(post, {UrlStr, [], "application/octet-stream", Payload}, [], [{body_format, binary}]) of
        {ok, {{_, 200, _}, _, Body}} ->
            %% Server frames responses with a 1-byte tag (0x00 = response,
            %% 0x01 = push). The HTTP path only sees responses, so we
            %% strip the tag before decoding the ETF payload.
            <<_Tag, EtfPayload/binary>> = Body,
            case binary_to_term(EtfPayload) of
                {ok, {ok, InnerPayload}} -> {ok, InnerPayload};
                {ok, {error, DomainErr}} -> {error, format_term(DomainErr)};
                {error, RpcErr} -> {error, format_rpc_error(RpcErr)}
            end;
        {ok, {{_, Code, _}, _, _}} ->
            {error, <<"HTTP error: ", (integer_to_binary(Code))/binary>>};
        {error, Reason} ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.

format_rpc_error({app_error, AppErr}) ->
    <<"Server error: ", (format_term(AppErr))/binary>>;
format_rpc_error({internal_error, _TraceId, Message}) when is_binary(Message) ->
    Message;
format_rpc_error({unknown_function, Name}) when is_binary(Name) ->
    <<"Unknown function: ", Name/binary>>;
format_rpc_error(malformed_request) ->
    <<"Malformed request">>;
format_rpc_error(Other) ->
    format_term(Other).

format_term(Term) ->
    list_to_binary(io_lib:format("~p", [Term])).

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
