%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et

-module(rebar_prv_help).

-behaviour(provider).

-export([init/1,
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
                                                               {deps, ?DEPS},
                                                               {example, "rebar3 help <task>"},
                                                               {short_desc, "Display a list of tasks or help for a given task or subtask."},
                                                               {desc, "Display a list of tasks or help for a given task or subtask."},
                                                               {opts, [
                                                                      {help_task, undefined, undefined, string, "Task to print help for."}
                                                                      ]}])),
    {ok, State1}.

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
    Providers = rebar_state:providers(State),
    try argparse:help(rebar3:global_cli(Providers),
                      #{progname => "rebar3", command => Path}) of
        HelpText ->
            io:format("~ts", [HelpText]),
            {ok, State}
    catch
        _:_ ->
            legacy_command_help(Path, Providers, State)
    end.

legacy_command_help([Name], Providers, State) ->
    task_help(default, list_to_atom(Name), Providers, State);
legacy_command_help([Namespace, Name], Providers, State) ->
    task_help(list_to_atom(Namespace), list_to_atom(Name), Providers, State).

task_help(Namespace, Name, Providers, State) ->
    case providers:get_provider(Name, Providers, Namespace) of
        not_found ->
            case providers:get_providers_by_namespace(Name, Providers) of
                [] ->
                    {error, io_lib:format("Unknown task ~p", [Name])};
                NSProviders ->
                    providers:help(NSProviders),
                    {ok, State}
            end;
        Provider ->
            providers:help(Provider),
            {ok, State}
    end.
