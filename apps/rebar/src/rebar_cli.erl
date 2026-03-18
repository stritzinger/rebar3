%% SPDX-License-Identifier: Apache-2.0
%% SPDX-FileCopyrightText: 2026 Dipl. Phys. Peer Stritzinger GmbH

-module(rebar_cli).

-export([global_cli/1]).

-include("rebar.hrl").

-spec global_cli([providers:t()]) -> argparse:command().
global_cli(Providers) ->
    #{
        help => ["Rebar3 is a tool for working with Erlang projects.",
                 "\n\nUsage: rebar3 [-h] [-v] <command>",
                 "\n\n  -h, --help    Print this help.",
                 "\n  -v, --version Show version information.",
                 "\n\nSet the environment variable DEBUG=1 for detailed output.",
                 "\n\nSeveral commands are available:\n\n",
                 commands,
                 "\n\nRun 'rebar3 help <command>' for details."],
        arguments => [
            #{name => help, short => $h, long => "-help", type => boolean,
              help => hidden},
            #{name => version, short => $v, long => "-version", type => boolean,
              help => hidden}
        ],
        commands => provider_commands(Providers)
    }.

provider_commands(Providers) ->
    BareProviders = [P || P <- Providers, is_bare_provider(P)],
    Default = maps:from_list(
        [{atom_to_list(providers:impl(P)), provider_command(P)}
         || P <- BareProviders, providers:namespace(P) =:= default]),
    Namespaced = maps:groups_from_list(
        fun(P) -> providers:namespace(P) end,
        [P || P <- BareProviders, providers:namespace(P) =/= default]),
    maps:fold(
        fun(NS, Ps, Acc) ->
            NSName = atom_to_list(NS),
            Acc#{
              NSName => #{
                  help => NSName ++ " namespace",
                  arguments => [],
                  commands => namespace_commands(NS, Ps)
              }
            }
        end,
        Default,
        Namespaced).

namespace_commands(Namespace, Providers) ->
    maps:from_list(
        [{atom_to_list(providers:impl(P)), provider_command(P)}
         || P <- Providers, is_bare_provider(P),
            providers:namespace(P) =:= Namespace]).

provider_command(Provider) ->
    Mod = providers:module(Provider),
    _ = code:ensure_loaded(Mod),
    case erlang:function_exported(Mod, cli, 0) of
        true ->
            Mod:cli();
        false ->
            %% Legacy providers may only expose getopt-style opts.
            rebar_legacy_cli:to_command(Provider)
    end.

is_bare_provider(P) when is_tuple(P), tuple_size(P) >= 5 ->
    element(1, P) =:= provider andalso element(5, P) =:= true;
is_bare_provider(_) ->
    false.
