-module({{name}}_prv).

-behaviour(provider).

-export([init/1, cli/0, do/1, format_error/1]).

-define(PROVIDER, {{name}}).
-define(DEPS, [app_discovery]).

%% ===================================================================
%% Public API
%% ===================================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([
        {name, ?PROVIDER},            % The 'user friendly' name of the task
        {module, ?MODULE},            % The module implementation of the task
        {bare, true},                 % The task can be run by the user, always true
        {deps, ?DEPS}                 % The list of dependencies
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.

-spec cli() -> argparse:command().
cli() ->
    #{help => "{{desc}}",
      arguments => []}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    {ok, State}.

-spec format_error(any()) ->  iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).
