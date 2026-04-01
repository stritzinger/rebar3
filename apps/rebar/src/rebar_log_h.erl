-module(rebar_log_h).

-behaviour(logger_handler).

%% Callbacks for `logger_handler`
-export([log/2]).

log(Event , #{formatter := {FmtMod, FmtConfig}}) ->
    Out = FmtMod:format(Event, FmtConfig),
    io:put_chars(Out).
