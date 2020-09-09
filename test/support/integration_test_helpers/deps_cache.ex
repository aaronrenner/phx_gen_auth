defmodule Phx.Gen.Auth.TestSupport.IntegrationTestHelpers.DepsCache do
  @moduledoc false

  @spec store_compiled_deps(String.t()) :: :ok | {:error, :mix_lock_not_found}
  def store_compiled_deps(app_path) when is_binary(app_path) do
    with {:ok, cache_path} <- fetch_compiled_deps_cache_path(app_path) do
      source_path = Path.join(app_path, "_build")

      File.mkdir_p!(base_compiled_deps_cache_path())
      File.rm_rf!(cache_path)
      atomic_copy!(source_path, cache_path)
      :ok
    end
  end

  @spec restore_compiled_deps(String.t()) :: :ok | :not_cached
  def restore_compiled_deps(app_path) when is_binary(app_path) do
    with {:ok, cache_path} <- fetch_compiled_deps_cache_path(app_path),
         true <- File.dir?(cache_path) do
      target_root_path = Path.join(app_path, "_build")

      File.rm_rf!(target_root_path)

      File.cp_r!(cache_path, target_root_path)

      :ok
    else
      _ ->
        :not_cached
    end
  end

  @spec fetch_compiled_deps_cache_path(String.t()) :: {:ok, String.t()} | {:error, :mix_lock_not_found}
  defp fetch_compiled_deps_cache_path(app_path) when is_binary(app_path) do
    case fetch_mix_lock_fingerprint(app_path) do
      {:ok, fingerprint} ->
        {:ok, Path.join(base_compiled_deps_cache_path(), fingerprint)}

      {:error, :file_not_found} ->
        {:error, :mix_lock_not_found}
    end
  end

  @spec fetch_mix_lock_fingerprint(String.t()) :: {:ok, String.t()} | {:error, :file_not_found}
  defp fetch_mix_lock_fingerprint(app_path) when is_binary(app_path) do
    with {:ok, mix_lock_contents} <- read_mix_lock_file(app_path) do
      {:ok, calculate_fingerprint(mix_lock_contents)}
    end
  end

  defp calculate_fingerprint(contents) do
    :crypto.hash(:sha256, contents)
    |> Base.encode32(padding: false)
  end

  defp read_mix_lock_file(app_path) do
    app_path
    |> mix_lock_file_path()
    |> File.read()
    |> case do
      {:ok, contents} -> {:ok, contents}
      {:error, _} -> {:error, :file_not_found}
    end
  end

  defp atomic_copy!(source_path, target_path) do
    tmp_path = Path.join([base_cache_path(), "tmp", random_string(10)])

    tmp_path
    |> Path.dirname()
    |> File.mkdir_p!()

    {_, 0} = System.cmd("cp", ["-RL", "#{source_path}/", tmp_path])

    File.rename(tmp_path, target_path)
  end

  defp mix_lock_file_path(app_path) do
    Path.join(app_path, "mix.lock")
  end

  defp base_compiled_deps_cache_path do
    Path.join(base_cache_path(), "compiled-deps")
  end

  defp base_cache_path do
    Path.join(__DIR__, "../../../tmp/deps_cache")
    |> Path.expand()
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode32()
    |> binary_part(0, length)
  end
end
