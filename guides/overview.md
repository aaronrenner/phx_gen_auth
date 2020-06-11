# Overview

The purpose of `mix phx.gen.auth` is to generate a pre-built authentication system into a Phoenix 1.5+ application that follows both security and elixir best practices. By generating code into the user's application instead of using a library, the user has complete freedom to modify the authentication system so it works best with their app. The following links have more information regarding the motivation and design of the code this generates.

* José Valim's blog post - [An upcoming authentication solution for Phoenix](https://dashbit.co/blog/a-new-authentication-solution-for-phoenix)
* [Original pull request on bare phoenix app][auth pr]
* [Original design spec](https://github.com/dashbitco/mix_phx_gen_auth_demo/blob/auth/README.md)

The following are notes about the generated authentication system.

## Password hashing

The password hashing mechanism defaults to `bcrypt` for
Unix systems and `pbkdf2` for Windows systems. Both
systems use [the Comeonin interface](https://hexdocs.pm/comeonin/).

## Forbidding access

The generated code ships with an auth module with a handful of
plugs that fetch the current account, requires authentication
and so on. For instance, for an app named Demo which invoked
`mix phx.gen.auth Accounts User users`, you will find a module
named `DemoWeb.UserAuth` with plugs such as:

  * `fetch_current_user` - fetches the current user information if
    available

  * `require_authenticated_user` - must be invoked after
    `fetch_current_user` and requires that a current exists and is
    authenticated

  * `redirect_if_user_is_authenticated` - used for the few
    pages that must not be available to authenticated users

## Confirmation

The generated functionality ships with an account confirmation
mechanism, where users have to confirm their account, typically
by e-mail. However, the generated code does not forbid users
from using the application if their accounts have not yet been
confirmed. You can trivially add this functionality by customizing
the plugs generated in the Auth module.

## Notifiers

The generated code is not integrated with any system to send
SMSs or e-mails for confirming accounts, reseting passwords,
etc. Instead it simply logs a message to the terminal. It is
your responsibility to integrate with the proper system after
generation.

## Tracking sessions

All sessions and tokens are tracked in a separate table. This
allows you to track how many sessions are active for each account.
You could even expose this information to users if desired.

Note that whenever the password changes (either via reset password
or directly), all tokens are deleted and the user has to login
again on all devices.

## Enumeration attacks

An enumeration attack allows an attacker to enumerate all e-mails
registered in the application. The generated authentication code
protects against enumeration attacks on all endpoints, except in
the registration and update e-mail forms. If your application is
really sensitive to enumeration attacks, you need to implement
your own registration workflow, which tends to be very different
from the workflow for most applications.

## Case sensitiveness

The e-mail lookup is made to be case insensitive. Case insensitive
lookups are the default in MySQL and MSSQL but require the
citext extension in Postgres.

## Concurrent tests

The generated tests run concurrently if you are using a database
that supports concurrent tests (Postgres).

[auth pr]: https://github.com/dashbitco/mix_phx_gen_auth_demo/pull/1
