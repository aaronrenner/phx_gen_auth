defmodule Mix.Phx.Gen.Auth.Injectors.ConfigTest do
  use ExUnit.Case, async: true

  alias Mix.Phx.Gen.Auth.{HashingLibrary, Injectors}

  describe "inject/2" do
    test "injects after \"use Mix.Config\" when hashing_library is bcrypt" do
      {:ok, hashing_library} = HashingLibrary.build("bcrypt")

      input = """
      use Mix.Config
      """

      {:ok, injected} = Injectors.Config.inject(input, hashing_library)

      assert injected ==
               """
               use Mix.Config

               # Only in tests, remove the complexity from the password hashing algorithm
               config :bcrypt_elixir, :log_rounds, 1
               """
    end

    test "injects after \"use Mix.Config\" when hashing_library is pbkdf2" do
      {:ok, hashing_library} = HashingLibrary.build("pbkdf2")

      input = """
      use Mix.Config
      """

      {:ok, injected} = Injectors.Config.inject(input, hashing_library)

      assert injected ==
               """
               use Mix.Config

               # Only in tests, remove the complexity from the password hashing algorithm
               config :pbkdf2_elixir, :rounds, 1
               """
    end

    test "injects after \"use Mix.Config\" when hashing_library is argon2" do
      {:ok, hashing_library} = HashingLibrary.build("argon2")

      input = """
      use Mix.Config
      """

      {:ok, injected} = Injectors.Config.inject(input, hashing_library)

      assert injected ==
               """
               use Mix.Config

               # Only in tests, remove the complexity from the password hashing algorithm
               config :argon2_elixir,
                 t_cost: 1,
                 m_cost: 8
               """
    end

    test "injects after \"use Mix.Config\" when there is existing content" do
      {:ok, hashing_library} = HashingLibrary.build("bcrypt")

      input = """
      use Mix.Config

      # Print only warnings and errors during test
      config :logger, level: :warn
      """

      {:ok, injected} = Injectors.Config.inject(input, hashing_library)

      assert injected ==
               """
               use Mix.Config

               # Only in tests, remove the complexity from the password hashing algorithm
               config :bcrypt_elixir, :log_rounds, 1

               # Print only warnings and errors during test
               config :logger, level: :warn
               """
    end

    test "injects after \"import Config\" when there is existing content" do
      {:ok, hashing_library} = HashingLibrary.build("bcrypt")

      input = """
      import Config

      # Print only warnings and errors during test
      config :logger, level: :warn
      """

      {:ok, injected} = Injectors.Config.inject(input, hashing_library)

      assert injected ==
               """
               import Config

               # Only in tests, remove the complexity from the password hashing algorithm
               config :bcrypt_elixir, :log_rounds, 1

               # Print only warnings and errors during test
               config :logger, level: :warn
               """
    end

    test "injects when there are windows line endings" do
      {:ok, hashing_library} = HashingLibrary.build("bcrypt")

      input = """
      import Config\r
      \r
      # Print only warnings and errors during test\r
      config :logger, level: :warn\r
      """

      {:ok, injected} = Injectors.Config.inject(input, hashing_library)

      assert injected ==
               """
               import Config\r
               \r
               # Only in tests, remove the complexity from the password hashing algorithm\r
               config :bcrypt_elixir, :log_rounds, 1\r
               \r
               # Print only warnings and errors during test\r
               config :logger, level: :warn\r
               """
    end

    test "returns :already_injected when config is already found in file" do
      {:ok, hashing_library} = HashingLibrary.build("bcrypt")

      input = """
      import Config

      # Print only warnings and errors during test
      config :logger, level: :warn

      # Only in tests, remove the complexity from the password hashing algorithm
      config :bcrypt_elixir, :log_rounds, 1

      """

      assert :already_injected = Injectors.Config.inject(input, hashing_library)
    end

    test "returns :already_injected when config is already found when using windows line endings" do
      {:ok, hashing_library} = HashingLibrary.build("bcrypt")

      input = """
      import Config\r
      \r
      # Print only warnings and errors during test\r
      config :logger, level: :warn\r
      \r
      # Only in tests, remove the complexity from the password hashing algorithm\r
      config :bcrypt_elixir, :log_rounds, 1\r
      \r
      """

      assert :already_injected = Injectors.Config.inject(input, hashing_library)
    end

    test "returns {:error, :unable_to_inject} when file doesn't confine \"import Config\" or \"use Mix.Config\"" do
      {:ok, hashing_library} = HashingLibrary.build("bcrypt")

      input = ""

      assert {:error, :unable_to_inject} = Injectors.Config.inject(input, hashing_library)
    end
  end

  describe "help_text/2" do
    test "returns a string with the expected help text" do
      {:ok, hashing_library} = HashingLibrary.build("bcrypt")

      file_path = Path.expand("config/test.exs")

      assert Injectors.Config.help_text(file_path, hashing_library) ==
               """
               Add the following to config/test.exs:

                   # Only in tests, remove the complexity from the password hashing algorithm
                   config :bcrypt_elixir, :log_rounds, 1
               """
    end
  end
end
