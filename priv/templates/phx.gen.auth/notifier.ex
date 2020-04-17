defmodule <%= inspect context.module %>.<%= inspect schema.alias %>Notifier do
  # For simplicity, this module simply logs messages to the terminal.
  # You should replace it by a proper e-mail or notification tool, such as:
  #
  #   * Swoosh - https://hexdocs.pm/swoosh
  #   * Bamboo - https://hexdocs.pm/bamboo
  #
  defp deliver(to, body) do
    require Logger
    Logger.debug(body)
    {:ok, %{to: to, body: body}}
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(<%= schema.singular %>, url) do
    deliver(<%= schema.singular %>.email, """

    ==============================

    Hi #{<%= schema.singular %>.email},

    You can confirm your account by visiting the url below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset password account.
  """
  def deliver_reset_password_instructions(<%= schema.singular %>, url) do
    deliver(<%= schema.singular %>.email, """

    ==============================

    Hi #{<%= schema.singular %>.email},

    You can reset your password by visiting the url below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update your e-mail.
  """
  def deliver_update_email_instructions(<%= schema.singular %>, url) do
    deliver(<%= schema.singular %>.email, """

    ==============================

    Hi #{<%= schema.singular %>.email},

    You can change your e-mail by visiting the url below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
