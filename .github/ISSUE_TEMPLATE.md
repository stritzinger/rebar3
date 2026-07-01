<!--
%CopyrightBegin%

SPDX-License-Identifier: Apache-2.0

SPDX-FileCopyrightText: Copyright 2015-2026 Rebar3 and its contributors

SPDX-FileCopyrightText: Copyright 2026 Dipl. Phys. Peer Stritzinger GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

%CopyrightEnd%
-->

### Pre-Check ###

- If you are filing for a bug, please do a quick search in current issues first
- For bugs, mention if you are willing or interested in helping fix the issue
- For questions or support, it helps to include context around your project or problem
- Think of a descriptive title (more descriptive than 'feature X is broken' unless it is fully broken)

### Environment ###

- Add the result of `rebar report` to your message:

```
$ rebar report "my failing command"
...
```

- Verify whether the version of rebar you're running is the latest release (see https://github.com/erlang/rebar3/releases)
- If possible, include information about your project and its structure. Open source projects or examples are always easier to debug.
  If you can provide an example code base to reproduce the issue on, we will generally be able to provide more help, and faster.

### Current behaviour ###

Describe the current behaviour. In case of a failure, crash, or exception, please include the result of running the command with debug information:

```
DEBUG=1 rebar <my failing command>
```

### Expected behaviour ###

Describe what you expected to happen.
