%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et

-module(rebar_prv_state).

-behaviour(provider).

-export([init/1,
         cli/0,
         do/1,
         format_error/1]).

-include("rebar.hrl").

-define(PROVIDER, state).
-define(DEPS, []).

%% ===================================================================
%% Public API
%% ===================================================================

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([{name, ?PROVIDER},
         {module, ?MODULE},
         {bare, false},
         {deps, ?DEPS}]),
    State1 = rebar_state:add_provider(State, Provider),
    {ok, State1}.

-spec cli() -> argparse:command().
cli() ->
    #{help => "Print current configuration state",
      arguments => []}. 

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    L = rebar_state:to_list(State),
    ?CONSOLE("State:", []),
    [?CONSOLE("  ~w: ~p", [K, V]) || {K,V} <- L],
    {ok, State}.

-spec format_error(any()) -> iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).
