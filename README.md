# amqp-filter: A SQL92 predicate evaluator in Erlang.

[![Build status](https://ci.appveyor.com/api/projects/status/johbwgju5aikqs76?svg=true)](https://ci.appveyor.com/project/pedro.armando/amqp-filter)

**amqp-filter** is an Erlang library that allows to evaluate SQL-92 predicates in the same way as in Azure Service Bus.

It supports the BNF grammar specified [here](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-sql-filter).

To create the lexer and parser we have used [leex](http://erlang.org/doc/man/leex.html) and [yecc](http://erlang.org/doc/man/yecc.html)


## Usage:
```
evaluator:evaluate("ID IN (123, 456, 789)", [{"ID", 456}]).
true
evaluator:evaluate("USERNAME = 'NICK' AND AGE > 18", [{ "USERNAME", "NICK" }, { "AGE", 25 }]).
true
evaluator:evaluate("YEAR % 4 = 0 AND (NOT YEAR % 100 = 0 OR YEAR % 400 = 0)", [{ "YEAR", 2018 }]).
false
```

## Integrate to your project

**amqp-filter** is available as a [Hex.pm package](https://hex.pm/packages/amqp-filter) and uses [Rebar 3](http://www.rebar3.org/) as its build system so
it can be easily integrated in your project.

### Rebar

Adding **amqp-filter** as a package dependency in your `rebar.config` file:

```erlang
{deps, [{amqp-filter, "1.0.0"}]}.
```

### Erlang.mk

Adding **amqp-filter** as a package dependency in your `Makefile`:

```make
DEPS = amqp-filter
dep_amqp-filter = hex 1.0.0
```

### Mix

Adding **amqp-filter** as a package dependency in your `mix.exs` file:

```elixir
def project do
  [
    deps: [{:amqp, "~> 1.0.0"}]
  ]
end
```

## Complete documentation

See https://hexdocs.pm/amqp_filter/ for a complete documentation.
