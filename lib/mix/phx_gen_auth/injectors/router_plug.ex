defmodule Mix.Phx.Gen.Auth.Injectors.RouterPlug do
  @moduledoc false

  alias Mix.Phoenix.{Context, Schema}
  alias Mix.Phx.Gen.Auth.Injector

  @anchor_line "plug :put_secure_browser_headers"

  def inject(file, %Context{schema: schema}) when is_binary(file) do
    Injector.inject_unless_contains(
      file,
      code_to_inject(schema),
      # Matches the entire line containing `anchor_line` and captures
      # the whitespace before the anchor. In the replace string
      #
      # * the entire matching line is inserted with \\0,
      # * the captured indent is inserted using \\1,
      # * the actual code is injected with &2,
      # * and the appropriate newline is injected using \\2
      &Regex.replace(~r/^(\s*)#{@anchor_line}.*(\r\n|\n|$)/Um, &1, "\\0\\1#{&2}\\2", global: false)
    )
  end

  def help_text(file_path, %Context{schema: schema}) do
    """
    Add the #{plug_name(schema)} plug to the :browser pipeline in #{Path.relative_to_cwd(file_path)}:

        pipeline :browser do
          ...
          #{@anchor_line}
          #{code_to_inject(schema)}
        end
    """
  end

  defp code_to_inject(%Schema{} = schema) do
    "plug " <> plug_name(schema)
  end

  defp plug_name(%Schema{} = schema) do
    ":fetch_current_#{schema.singular}"
  end
end
