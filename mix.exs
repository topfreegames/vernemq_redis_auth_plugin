defmodule RedisAuthPlugin.Mixfile do
  use Mix.Project

  def project do
    [app: :redis_auth_plugin,
     version: "0.1.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  defp vmq_plugin_hooks do
    hooks = [
      {RedisAuthPlugin, :auth_on_register, 5, []},
      {RedisAuthPlugin, :auth_on_subscribe, 3, []},
      {RedisAuthPlugin, :auth_on_publish, 6, []},
    ]
    {:vmq_plugin_hooks, hooks}
  end

  def application do
    [
      mod: {RedisAuthPlugin, []},
      extra_applications: [:logger, :redix, :pbkdf2],
      env: [vmq_plugin_hooks()]
    ]
  end

  defp deps do
    [
      {:pbkdf2, "~> 2.0"},
      {:redix, ">= 0.0.0"},
      {:distillery, "~> 1.4", runtime: false},
    ]
  end
end
