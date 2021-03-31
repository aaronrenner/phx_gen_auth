# Overview

The purpose of `mix phx.gen.auth` is to generate a pre-built authentication system into a Phoenix 1.5+ application that follows both security and Elixir best practices. By generating code into the user's application instead of using a library, the user has complete freedom to modify the authentication system so it works best with their app. The following links have more information regarding the motivation and design of the code this generates.

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
    `fetch_current_user` and requires that a current user exists and is
    authenticated

  * `redirect_if_user_is_authenticated` - used for the few
    pages that must not be available to authenticated users

## Confirmation

The generated functionality ships with an account confirmation
mechanism, where users have to confirm their account, typically
by email. However, the generated code does not forbid users
from using the application if their accounts have not yet been
confirmed. You can trivially add this functionality by customizing
the plugs generated in the Auth module.

## Notifiers

The generated code is not integrated with any system to send
SMS or email messages for confirming accounts, resetting passwords,
etc. Instead it simply logs a message to the terminal. It is
your responsibility to integrate with the proper system after
generation.

## Tracking sessions

All sessions and tokens are tracked in a separate table. This
allows you to track how many sessions are active for each account.
You could even expose this information to users if desired.

Note that whenever the password changes (either via reset password
or directly), all tokens are deleted and the user has to log in
again on all devices.

## User Enumeration attacks

A user enumeration attack allows an attacker to enumerate all emails
registered in the application. For example, if trying to log in with
a registered email and a wrong password returns a different error 
than trying to log in with an email that was never registered, an
attacker could use this discrepency to find out which emails have 
accounts.

The generated authentication code protects against enumeration attacks 
on all endpoints, except in the registration and update email forms. If 
your application is really sensitive to enumeration attacks, you need to
implement your own registration workflow, which tends to be very different
from the workflow for most applications.

## Case sensitiveness

The email lookup is made to be case insensitive. Case insensitive
lookups are the default in MySQL and MSSQL but use the
[`citext` extension in PostgreSQL](https://www.postgresql.org/docs/current/citext.html).

Note `citext` is part of Postgres itself and is bundled with it in
most operating systems and package managers. `phx.gen.auth` takes
care of creating the extension and no extra work is necessary in
the majority of cases. If by any chance your package manager splits
`citext` into a separate package, you will get an error while
migrating and you can most likely solve it by installing the
`postgres-contrib` package.

## Concurrent tests

The generated tests run concurrently if you are using a database
that supports concurrent tests (Postgres).

[auth pr]: https://github.com/dashbitco/mix_phx_gen_auth_demo/pull/1
