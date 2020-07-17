# Contributing to Phx.Gen.Auth

Please take a moment to review this document in order to make the contribution
process easy and effective for everyone involved!

## Background

This project is serving as the incubator for the `mix phx.gen.auth` code
generator before it's merged into [phoenix
core](https://github.com/phoenixframework/phoenix). By initially having this as
a separate project, we can make quicker changes and bug fixes while not having
to wait for the next phoenix release. However, with the goal of eventually
merging this project into phoenix core, it's import this project's code and the
code it generates stays consistent with the rest of phoenix.

## Running tests

To get started, we must be running Elixir 1.8+ and have installed this project's
dependencies with `mix deps.get`.

### Unit Tests

The unit tests are fast and provide test coverage around areas such as code
injection logic. Use the following command to run only the unit tests:

```
$ mix test --exclude=integration
```

### Integration tests

The integration tests are slower, require an internet connection and a database. These tests:

  * generate a new phoenix app,
  * install phx.gen.auth,
  * install dependencies with `mix deps.get`,
  * run the generated app's test suite and
  * check the generated app's formatting with `mix format --check-formatted`.

There is no requirement that the `phx_new` archive is installed on our
system because `phx_new` is a defined as test dependency in `mix.exs`.

To ensure the proper databases are running, start up the appropriate containers
using docker-compose.

```
$ docker-compose up
```

This starts the following databases:
* Postgresql
* MySQL
* SQL Server

Next, run the integration tests

```
$ mix test --only=integration
```

During the integration tests, apps are generated to `test_apps/`. It can be
useful to look in this directory to see the code that Phx.Gen.Auth installed
into this project.

#### Troubleshooting

Sometimes when the test suite is stopped unexpectedly, the generated apps can
get into a weird state. The easiest way to fix this issue is to delete the
`test_apps` directory and run the test suite again.

```
$ rm test_apps
```
