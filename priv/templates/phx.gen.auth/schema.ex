defmodule <%= inspect schema.module %> do
  use Ecto.Schema
  import Ecto.Changeset

  <%= if requires_inspect_impls? do %>##
  # Deriving the Inspect protocol is only supported in Elixir 1.8+.
  #
  # In order to protect against accidentally leaking passwords, a custom
  # `Inspect` impl has been added to the bottom of this module.
  #
  # After upgrading to Elixir 1.8+, the if statement around @derive
  # and the inspect impl at the bottom of this module can be removed
  ##
  if Version.compare(System.version(), "1.8.0") in [:eq, :gt] do
    @derive {Inspect, except: [:password]}
  end
  <% else %>@derive {Inspect, except: [:password]}<% end %>
  schema <%= inspect schema.table %> do
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime

    timestamps()
  end

  @doc """
  A <%= schema.singular %> changeset for registration.

  It is important to validate the length of both e-mail and password.
  Otherwise databases may truncate the e-mail without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to for certain algorithms.
  """
  def registration_changeset(<%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> cast(attrs, [:email, :password])
    |> validate_email()
    |> validate_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, <%= inspect schema.repo %>)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 80)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password()
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A <%= schema.singular %> changeset for changing the e-mail.

  It requires the e-mail to change otherwise an error is added.
  """
  def email_changeset(<%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A <%= schema.singular %> changeset for changing the password.
  """
  def password_changeset(<%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> cast(attrs, [:password])
    |> validate_confirmation(:password)
    |> validate_password()
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(<%= schema.singular %>) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(<%= schema.singular %>, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  Returns the given <%= schema.singular %> if valid,

  If there is no <%= schema.singular %> or the <%= schema.singular %> doesn't have a password,
  we hash a blank password to avoid timing attacks.
  """
  def valid_password?(%<%= inspect schema.module %>{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.hash_pwd_salt("unused hash to avoid timing attacks")
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end<%= if requires_inspect_impls? do %>

  ###
  # This `Inspect` implementation is only needed for Elixir versions < 1.8
  # and prevents `inspect/2` from returning sensitive fields.
  #
  # This can be removed after upgrading to Elixir 1.8+ and sensitive
  # fields can be controlled with the the following line at the top of this
  # module.
  #
  #     @derive {Inspect, except: [:password]}
  ###
  if Version.compare(System.version(), "1.8.0") == :lt do
    defimpl Inspect do
      @fields_to_exclude [:password]

      import Inspect.Algebra

      def inspect(<%= schema.singular %>, opts) do
        colorless_opts = %{opts | syntax_colors: []}
        name = Inspect.Atom.inspect(@for, colorless_opts)

        open = color("#" <> name <> "<", :map, opts)
        sep = color(",", :map, opts)
        close = color(">", :map, opts)

        map = Map.drop(<%= schema.singular %>, @fields_to_exclude ++ [:__struct__, :__exception__])

        # Use the :limit option and an extra element to force
        # `container_doc/6` to append "...".
        opts = %{opts | limit: min(opts.limit, map_size(map))}

        field_list =
          map
          |> Map.to_list()
          |> Kernel.++(["..."])

        container_doc(open, field_list, close, opts, &Inspect.List.keyword/2, separator: sep, break: :strict)

      end
    end
  end<% end %>
end
