-module(libero_push_ffi).
-export([ensure_started/0, pg_join/1, pg_leave/1, pg_send/2]).

-define(SCOPE, libero_push).

ensure_started() ->
    case pg:start(?SCOPE) of
        {ok, _Pid} -> nil;
        {error, {already_started, _Pid}} -> nil;
        {error, Reason} -> error({libero_push_start_failed, Reason})
    end.

pg_join(Topic) ->
    ok = pg:join(?SCOPE, Topic, self()),
    nil.

pg_leave(Topic) ->
    _ = pg:leave(?SCOPE, Topic, self()),
    nil.

pg_send(Topic, Frame) ->
    Members = pg:get_members(?SCOPE, Topic),
    Self = self(),
    lists:foreach(fun(Pid) ->
        %% Skip self to avoid re-processing our own push messages
        %% in the WebSocket handler's message loop.
        case Pid of
            Self -> ok;
            _ -> Pid ! {libero_push, Frame}
        end
    end, Members),
    nil.
