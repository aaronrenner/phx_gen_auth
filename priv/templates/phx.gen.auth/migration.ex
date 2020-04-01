defmodule <%= inspect schema.repo %>.Migrations.Create<%= inspect schema.alias %>AuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:<%= schema.table %>) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:<%= schema.table %>, [:email])

    create table(:<%= schema.singular %>_tokens) do
      add :<%= schema.singular %>_id, references(:<%= schema.table %>, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :inserted_at, :naive_datetime
    end

    create unique_index(:<%= schema.singular %>_tokens, [:context, :token])
  end
end
