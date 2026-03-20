<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- SPDX-FileCopyrightText: 2026 Dipl. Phys. Peer Stritzinger GmbH -->

# Plugin CLI Migration (rebar 4.x)

In rebar `4.x.x` and following releases, plugin providers should export a
`cli/0` callback that returns an `argparse:command()` map.

Legacy provider option specs in `providers:create([{opts, ...}])` are a
temporary compatibility path and will be removed in a later release.

## Temporary compatibility (deprecated)

If your plugin still relies on legacy provider options and does not expose
`cli/0`, rebar currently keeps it working through temporary compatibility.
Treat this as deprecated behavior and migrate away from it:

1. Runtime argument parsing fallback for providers without `cli/0`.
2. `rebar help` fallback for providers without `cli/0`.
3. Type normalization while converting old option specs.
4. Automatic reserved-short sanitization in legacy option conversion.
   Globally reserved short flags like `-v`/`-h` may be dropped during
   conversion so help/CLI validation can still succeed.
5. Duplicate short flags within a single legacy provider option spec are not
   supported.
   If two options in one command reuse the same short flag, plugin authors
   must migrate to `cli/0` and assign unique short flags or rely on long
   flags instead.

## Reserved flags

The following flags are reserved globally by rebar and must not be used by
plugin options:

- `-v` / `--version`
- `-h` / `--help`

## Duplicate short flags

Reused short flags such as defining both `-c` for different options are not
supported within one command in the compatibility path.

Reusing the same short flag in different subcommands is allowed by `argparse`
and is not a problem by itself.

If your provider currently relies on duplicate short flags, migrate it to
`cli/0` and do one of the following:

- assign unique short flags, or
- drop the short alias and keep a long flag for one or more options.

For legacy `providers:create([{opts, ...}])` specs, ensure every option with a
conflicting short alias also has a usable long flag before depending on the
compatibility path.

## Migration example

### Provider definition

#### Before (legacy provider opts)

```erlang
Provider = providers:create([
    {name, mytask},
    {module, ?MODULE},
    {bare, true},
    {opts, [
        {output, $o, "output", string, "Output file"},
        {verbose, $v, "verbose", {boolean, false}, "Verbose output"}
    ]}
]).
```

#### After (argparse with `cli/0`)

```erlang
-export([cli/0]).

Provider = providers:create([
    {name, mytask},
    {module, ?MODULE},
    {bare, true}
]).

-spec cli() -> argparse:command().
cli() ->
    #{help => "Run my task.",
      arguments => [
        #{name => output,
          short => $o,
          long => "-output",
          help => "Output file"},
        #{name => verbose,
          short => $V,
          long => "-verbose",
          type => boolean,
          default => false,
          help => "Verbose output"}
      ]}.
```

#### After (subcommand-style `cli/0`)

```erlang
-export([cli/0]).

Provider = providers:create([
    {name, mynamespace},
    {module, ?MODULE},
    {bare, true}
]).

-spec cli() -> argparse:command().
cli() ->
    #{help => "Task with subcommands.",
      arguments => [],
      commands => #{
        "run" => #{
            help => "Run action",
            arguments => [
              #{name => target,
                help => "Target name"}
            ]
        },
        "check" => #{
            help => "Check action",
            arguments => []
        }
      }}.
```

### `do/1` argument handling

The argument access pattern did not change much: you still read from
`rebar_state:command_parsed_args(State)`, keep the tuple shape, and use
`proplists:get_value/3`.

```erlang
do(State) ->
    {Parsed, _Rest} = rebar_state:command_parsed_args(State),
    Output = proplists:get_value(output, Parsed, undefined),
    %% do something
    {ok, State}.
```

For providers that define `cli/0` (argparse path), `_Rest` is usually `[]` and
new plugins should normally ignore it. Non-empty rest arguments are mainly a
legacy fallback behavior, where extra non-option arguments can remain in the
getopt result.

## Migration checklist

### Implementation
1. Add `cli/0` to every provider module.
2. Move provider option definitions from `providers:create([{opts, ...}])` into `cli/0`.
3. Stop using reserved flags (`-v`, `--version`, `-h`, `--help`).
4. Remove duplicate flags.

### Clean up and Testing
5. Review argument handling.
6. Verify `rebar help <task>` and `rebar <task> ...` for all plugin commands.
