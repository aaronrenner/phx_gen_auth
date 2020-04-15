defmodule Mix.Phx.Gen.Auth.Injector do
  @moduledoc false

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
end
