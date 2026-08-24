# Plugin Locking

## Considerations

- Current implementation distinguishes cleanly between application dependencies and plugins/plugin dependencies. We should keep that separation.
- Plugins might be needed to fetch other dependencies making it impossible to build the dependency tree ahead of fetching and compilation.
- We want to avoid updates on the Erlang path while running `rebar`. This would be required to support different versions of the same dependency for different plugins. We need version picking similar to what we have for application dependencies. 

=> We need version picking and a dependency tree, but we can not build that tree ahead of fetching and compiling. We must build it during fetching and compiling. (This is different for plugins compared to normal dependencies.)

## Goals

- Keep ordinary application dependencies and plugin dependencies separated.
- Review the existing version picking for plugin dependencies that is done during fetching and compilation and ensure in the final plugin dependency tree:
    - At the same level plugin dependencies win over ordinary dependencies (Note that this is only regarding the plugin dependency tree and plugins can depend on other plugins or other applications using `plugins` or `deps` in their `rebar.config`).
    - Higher level wins.
    - On the same level first in configuration file wins.
- Lock the implicitly defined dependency tree of plugins in the state and extend the lock file.
- Extend command line interface for an unlock feature for plugins.

## Roadmap

1. Review and eventually adjust version picking for plugin dependencies and (implicit) dependency tree generation. Extend testing.
2. Add lock mechanism during compile and upgrade.
3. Add unlock feature for plugins.
    ```
    rebar plugins unlock <plugin>
    rebar plugins unlock --all
    ```

## Implementation Details by Example

**Example 1:**
```
root
├─ dep1
│   └─ dep2 v1.0
└─ plugin1
    └─ dep2 v2.0
```

Should resolve to the separate dependency trees:

```
root (dependencies) // fetched in _build/PROFILE/lib
└─ dep1
    └─ dep2 v1.0

root (plugins)      // fetched in _build/PROFILE/plugins
└─ plugin1
    └─ dep2 v2.0
```

**Example 2:**

```
root
└─ dep1
    ├─ plugin1
    │   └─ dep2 v1.0
    └─ plugin2
        └─ dep2 v2.0
```

Should resolve to the dependency trees:

```
root (dependencies)
└─ dep1

root (plugins)
├─ plugin1
│   └─ dep2 v1.0
└─ plugin2
    └─ dep2 v1.0 // version picking v1.0 over v2.0 - same level, picking by order
```

**Example 3:**

```
root
└─ plugin1
    ├─ plugin2 // required to fetch dep1 
    │   └─ dep2 v1.0
    └─ dep1
        └─ dep2 v2.0
```

Should resolve to the dependency tree:

```
root (plugins)
└─ plugin1
    ├─ plugin2 // required to fetch dep1 
    │   └─ dep2 v1.0
    └─ dep1
        └─ dep2 v1.0 // version picking v1.0 over v2.0 - same level, plugin before dep
```

The tree is build implicitly during fetching and compiling:

1. `dep2 v1.0` fetch and compile
2. `plugin2` compile
3. `dep2 v2.0` is skipped (plugin dependencies before other dependencies)
4. `dep1` fetch and compile
5. `plugin1` compile

**Example 4:**

```
root
└─ plugin1
    ├─ plugin2 // required to fetch dep1 
    │   └─ dep2 v1.0
    ├─ dep1
    │   └─ dep2 v2.0
    └─ dep2 v1.5
```

Should resolve to the dependency tree:

```
root (plugins)
└─ plugin1
    ├─ plugin2 // required to fetch dep1 
    │   └─ dep2 v1.5
    ├─ dep1
    │   └─ dep2 v1.5
    └─ dep2 v1.5
```

The tree is build implicitly during fetching and compiling:

1. `dep2 v1.5` fetch and compile
2. `dep2 v1.0` is skipped (higher level wins) 
3. `plugin2` compile
4. `dep2 v2.0` is skipped (plugin dependencies before other dependencies)
5. `dep1` fetch and compile
6. `plugin1` compile


## New State Entry

- Keep deps -> `locks`
- Add plugin dependencies -> `plugin_locks`

## New Lock File Shape

**Illustrative Example**
```
{"2.0.0",[
  {deps, [{<<"dep2">>,{pkg,<<"dep2">>,<<"v2.1">>},0}]},
  {plugins, [
    {<<"plugin1">>,{pkg,<<"plugin1">>,<<"1.2.0">>},0},
    {<<"plugin2">>,{git,"https://github.com/example/plugin2.git ",
                            {ref,"{Git Commit Hash}"}},1},
    {<<"dep2">>, {pkg, <<"dep2">>, <<"v1.5">>}, 1}
  ]}
]}.
[
  {pkg_hash,[
    {deps, [{<<"dep2">>, <<"{dep2_inner_checksum_v2.1}">>]}},
    {plugins, [
        {<<"plugin1">>, <<"{plugin1_inner_checksum}">>},
        {<<"dep2">>, <<"{dep2_inner_checksum_v1.5}">>}
    ]}
  ]},
  {pkg_hash_ext,[
    {deps, [{<<"dep2">>, <<"{dep2_outer_checksum_v2.1}">>}]},
    {plugins, [
        {<<"plugin1">>, <<"{plugin1_outer_checksum}">>},
        {<<"dep2">>, <<"{dep2_outer_checksum_v1.5}">>}
    ]}
  ]}
