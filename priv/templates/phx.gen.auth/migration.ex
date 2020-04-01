defmodule <%= inspect schema.repo %>.Migrations.Create<%= inspect schema.alias %>AuthTables do
  use Ecto.Migration

  def change do<%= if Enum.any?(migration.extensions) do %><%= for extension <- migration.extensions do %>
    <%= extension %><% end %>
<% end %>
    create table(:<%= schema.table %>) do
      <%= migration.column_definitions[:email] %>
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:<%= schema.table %>, [:email])

    create table(:<%= schema.singular %>_tokens) do
      add :<%= schema.singular %>_id, references(:<%= schema.table %>, on_delete: :delete_all), null: false
      <%= migration.column_definitions[:token] %>
      add :context, :string, null: false
      add :sent_to, :string
      add :inserted_at, :naive_datetime
    end

    create unique_index(:<%= schema.singular %>_tokens, [:context, :token])
  end
end
