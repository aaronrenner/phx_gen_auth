defmodule Mix.Phx.Gen.Auth.Injector do
  @moduledoc false

  alias Mix.Phoenix.{Context, Schema}
  alias Mix.Phx.Gen.Auth.HashingLibrary

  @type schema :: %Schema{}
  @type context :: %Context{schema: schema}

  @doc """
  Injects a dependency into the contents of mix.exs
  """
  @spec inject_mix_dependency(String.t(), String.t()) :: {:ok, String.t()} | :already_injected | {:error, :unable_to_inject}
  def inject_mix_dependency(mixfile, dependency) do
    with :ok <- ensure_not_already_injected(mixfile, dependency),
         {:ok, new_mixfile} <- do_inject_dependency(mixfile, dependency) do
      {:ok, new_mixfile}
    end
  end

  @doc """
  Injects configuration for test environment into `file`.
  """
  @spec inject_test_config(String.t(), HashingLibrary.t()) :: {:ok, String.t()} | :already_injected | {:error, :unable_to_inject}
  def inject_test_config(file, %HashingLibrary{} = hashing_library) when is_binary(file) do
    code_to_inject =
      hashing_library
      |> test_config_code()
      |> normalize_line_endings_to_file(file)

    inject_unless_contains(
      file,
      code_to_inject,
      # Matches the entire line and captures the line ending. In the
      # replace string:
      #
      # * the entire matching line is inserted with \\0,
      # * the actual code is injected with &2,
      # * and the appropriate newlines are injected using \\2.
      &Regex.replace(~r/(use Mix\.Config|import Config)(\r\n|\n|$)/, &1, "\\0\\2#{&2}\\2", global: false)
    )
  end

  @doc """
  Instructions to provide the user when `inject_test_config/2` fails.
  """
  @spec help_text_for_inject_test_config(String.t(), HashingLibrary.t()) :: String.t()
  def help_text_for_inject_test_config(file_path, %HashingLibrary{} = hashing_library) do
    """
    Add the following to #{Path.relative_to_cwd(file_path)}:

    #{hashing_library |> test_config_code() |> indent_spaces(4)}
    """
  end

  defp test_config_code(%HashingLibrary{test_config: test_config}) do
    String.trim("""
    # Only in tests, remove the complexity from the password hashing algorithm
    #{test_config}
    """)
  end

  @router_plug_anchor_line "plug :put_secure_browser_headers"

  @doc """
  Injects the fetch_current_<schema> plug into router's browser pipeline
  """
  @spec inject_router_plug(String.t(), context) :: {:ok, String.t()} | :already_injected | {:error, :unable_to_inject}
  def inject_router_plug(file, %Context{schema: schema}) when is_binary(file) do
    inject_unless_contains(
      file,
      router_plug_code(schema),
      # Matches the entire line containing `anchor_line` and captures
      # the whitespace before the anchor. In the replace string
      #
      # * the entire matching line is inserted with \\0,
      # * the captured indent is inserted using \\1,
      # * the actual code is injected with &2,
      # * and the appropriate newline is injected using \\2
      &Regex.replace(~r/^(\s*)#{@router_plug_anchor_line}.*(\r\n|\n|$)/Um, &1, "\\0\\1#{&2}\\2", global: false)
    )
  end

  @doc """
  Instructions to provide the user when `inject_router_plug/2` fails.
  """
  @spec help_text_for_inject_router_plug(String.t(), context) :: String.t()
  def help_text_for_inject_router_plug(file_path, %Context{schema: schema}) do
    """
    Add the #{router_plug_name(schema)} plug to the :browser pipeline in #{Path.relative_to_cwd(file_path)}:

        pipeline :browser do
          ...
          #{@router_plug_anchor_line}
          #{router_plug_code(schema)}
        end
    """
  end

  defp router_plug_code(%Schema{} = schema) do
    "plug " <> router_plug_name(schema)
  end

  defp router_plug_name(%Schema{} = schema) do
    ":fetch_current_#{schema.singular}"
  end

  @doc """
  Injects code unless the existing code already contains `code_to_inject`
  """
  @spec inject_unless_contains(String.t(), String.t(), (String.t(), String.t() -> String.t())) ::
          {:ok, String.t()} | :already_injected | {:error, :unable_to_inject}
  def inject_unless_contains(code, code_to_inject, inject_fn) when is_binary(code) and is_binary(code_to_inject) and is_function(inject_fn, 2) do
    with :ok <- ensure_not_already_injected(code, code_to_inject) do
      new_code = inject_fn.(code, code_to_inject)

      if code != new_code do
        {:ok, new_code}
      else
        {:error, :unable_to_inject}
      end
    end
  end

  @doc """
  Injects snippet before the final end in a file
  """
  @spec inject_before_final_end(String.t(), String.t()) :: {:ok, String.t()} | :already_injected
  def inject_before_final_end(code, code_to_inject) when is_binary(code) and is_binary(code_to_inject) do
    if String.contains?(code, code_to_inject) do
      :already_injected
    else
      new_code =
        code
        |> String.trim_trailing()
        |> String.trim_trailing("end")
        |> Kernel.<>(code_to_inject)
        |> Kernel.<>("end\n")

      {:ok, new_code}
    end
  end

  @spec ensure_not_already_injected(String.t(), String.t()) :: :ok | :already_injected
  defp ensure_not_already_injected(file, inject) do
    if String.contains?(file, inject) do
      :already_injected
    else
      :ok
    end
  end

  @spec do_inject_dependency(String.t(), String.t()) :: {:ok, String.t()} | {:error, :unable_to_inject}
  defp do_inject_dependency(mixfile, dependency) do
    string_to_split_on = """
      defp deps do
        [
    """

    case split_with_self(mixfile, string_to_split_on) do
      {beginning, splitter, rest} ->
        new_mixfile = IO.iodata_to_binary([beginning, splitter, "      ", dependency, ?\,, ?\n, rest])
        {:ok, new_mixfile}

      _ ->
        {:error, :unable_to_inject}
    end
  end

  @spec split_with_self(String.t(), String.t()) :: {String.t(), String.t(), String.t()} | :error
  defp split_with_self(contents, text) do
    case :binary.split(contents, text) do
      [left, right] -> {left, text, right}
      [_] -> :error
    end
  end

  @spec normalize_line_endings_to_file(String.t(), String.t()) :: String.t()
  defp normalize_line_endings_to_file(code, file) do
    String.replace(code, "\n", get_line_ending(file))
  end

  @spec get_line_ending(String.t()) :: String.t()
  defp get_line_ending(file) do
    case Regex.run(~r/\r\n|\n|$/, file) do
      [line_ending] -> line_ending
      [] -> "\n"
    end
  end

  defp indent_spaces(string, number_of_spaces) when is_binary(string) and is_integer(number_of_spaces) do
    indent = String.duplicate(" ", number_of_spaces)

    string
    |> String.split("\n")
    |> Enum.map(&(indent <> &1))
    |> Enum.join("\n")
  end
end
