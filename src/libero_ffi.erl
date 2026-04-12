%% Libero RPC panic-catching FFI.
%%
%% try_call(F) runs the zero-arg function F and returns {ok, Result}
%% on success, or {error, ReasonBinary} if the function panics or
%% throws. The reason is stringified so the caller can log it
%% alongside a trace_id without pattern-matching on arbitrary
%% Erlang term shapes.

-module(libero_ffi).
-export([try_call/1, encode/1, decode/1, trap_signals/0]).

encode(Term) ->
    erlang:term_to_binary(Term).

decode(Bin) ->
    erlang:binary_to_term(Bin, [safe]).

%% Install signal handlers so libero exits cleanly when its parent
%% build script is killed (Ctrl-C, SIGTERM from sandbox, etc.).
%% Without this, a stuck or in-progress libero process can survive
%% its parent and spin at 99% CPU.
trap_signals() ->
    os:set_signal(sigterm, handle),
    os:set_signal(sighup, handle),
    spawn(fun signal_loop/0),
    nil.

signal_loop() ->
    receive
        {signal, sigterm} -> erlang:halt(1);
        {signal, sighup}  -> erlang:halt(1);
        _Other            -> signal_loop()
    end.

try_call(F) ->
    try F() of
        Result -> {ok, Result}
    catch
        Class:Reason:Stacktrace ->
            Message = io_lib:format(
                "~p: ~p~nstacktrace: ~p",
                [Class, Reason, Stacktrace]
            ),
            {error, erlang:iolist_to_binary(Message)}
    end.
