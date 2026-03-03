%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et

-module(rebar_prv_help).

-behaviour(provider).

-export([init/1,
         cli/0,
         do/1,
         format_error/1]).

-include("rebar.hrl").

-define(PROVIDER, help).
-define(DEPS, []).

%% ===================================================================
%% Public API
%% ===================================================================

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    State1 = rebar_state:add_provider(State, providers:create([{name, ?PROVIDER},
                                                               {module, ?MODULE},
                                                               {bare, true},
                                                               {deps, ?DEPS}])),
    {ok, State1}.

-spec cli() -> argparse:command().
cli() ->
    #{help => "Display a list of tasks or help for a given task or subtask.",
      arguments => [
        #{name => help_task,
          type => string,
          nargs => list,
          required => false,
          help => "Task to print help for."}
    ]}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    case rebar_state:command_args(State) of
        [] ->
            help(State),
            {ok, State};
        HelpPath when is_list(HelpPath), length(HelpPath) =< 2 ->
            command_help(HelpPath, State);
        _ ->
            {error, "Too many arguments given. " ++
                 "Usage: rebar3 help [<namespace>] <task>"}
    end.

-spec format_error(any()) -> iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

%%
%% print help/usage string
%%
help(State) ->
    io:format("~ts",
              [argparse:help(
                  rebar3:global_cli(rebar_state:providers(State)),
                  #{progname => "rebar3"})]).

command_help(Path, State) ->
    Cli = rebar3:global_cli(rebar_state:providers(State)),
    HelpText = argparse:help(Cli,
                             #{progname => "rebar3",
                               command => Path}),
    io:format("~ts", [HelpText]),
    {ok, State}.
