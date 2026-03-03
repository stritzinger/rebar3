%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et

-module(rebar_prv_get_deps).

-behaviour(provider).

-export([init/1,
         cli/0,
         do/1,
         format_error/1]).

-define(PROVIDER, 'get-deps').
-define(DEPS, [lock]).

%% ===================================================================
%% Public API
%% ===================================================================

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([{name, ?PROVIDER},
                                 {module, ?MODULE},
                                 {deps, ?DEPS},
                                 {bare, true},
                                 {profiles, []}]),
    {ok, rebar_state:add_provider(State, Provider)}.

-spec cli() -> argparse:command().
cli() ->
    #{help => "Fetch dependencies.",
      arguments => []}. 

-spec do(rebar_state:t()) -> {ok, rebar_state:t()}.
do(State) -> {ok, State}.

-spec format_error(any()) -> iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).
