# amqp-filter: An SQL92 predicate evaluator in Erlang.

[![Build status](https://ci.appveyor.com/api/projects/status/johbwgju5aikqs76?svg=true)](https://ci.appveyor.com/project/pedro.armando/amqp-filter)

**amqp-filter** is an Erlang library that allows to evaluate SQL-92 predicates in the same way as in Azure Service Bus.

It supports the BNF grammar specified [here](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-sql-filter).

To create the lexer and parser we have used [leex](http://erlang.org/doc/man/leex.html) and [yecc](http://erlang.org/doc/man/yecc.html)


## Usage:
```
amqp_filter:evaluate("ID IN (123, 456, 789)", [{"ID", 456}]).
true
amqp_filter:evaluate("USERNAME = 'NICK' AND AGE > 18", [{ "USERNAME", "NICK" }, { "AGE", 25 }]).
true
amqp_filter:evaluate("YEAR % 4 = 0 AND (NOT YEAR % 100 = 0 OR YEAR % 400 = 0)", [{ "YEAR", 2018 }]).
false
```

## Integrating to your project

**amqp-filter** is available as a [Hex.pm package](https://hex.pm/packages/amqp_filter) and uses [Rebar 3](http://www.rebar3.org/) as its build system so
it can be easily integrated in your project.

### Rebar

Adding **amqp-filter** as a package dependency in your `rebar.config` file:

```erlang
{deps, [{amqp_filter, "0.3.7"}]}.
```

### Erlang.mk

Adding **amqp-filter** as a package dependency in your `Makefile`:

```make
DEPS = amqp_filter
dep_amqp_filter = hex 0.3.7
```

### Mix

Adding **amqp-filter** as a package dependency in your `mix.exs` file:

```elixir
def project do
  [
    deps: [{:amqp_filter, "~> 0.3.7"}]
  ]
end
```

## Complete documentation

See https://hexdocs.pm/amqp_filter/ for a complete documentation.

## Building

It is recommended to build `amqp-filter` on Linux.

- Download Erlang/OTP 20.x or later from [Erlang Solutions](https://www.erlang-solutions.com/resources/download.html)
- Run `./build.sh` 