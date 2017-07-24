defmodule AuthPlugin.Mixfile do
  use Mix.Project

  def project do
    [app: :auth_plugin,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger],
     env: [
       vmq_plugin_hooks:
       [{:auth_on_register, AuthPlugin, :auth_on_register,5,[]},
        {:auth_on_publish, AuthPlugin, :auth_on_publish,6,[]},
        {:auth_on_subscribe, AuthPlugin, :auth_on_subscribe,3,[]},],
       ]]
  end

  defp deps do
    [
      {:pbkdf2, "~> 2.0"},
      {:redix, ">= 0.0.0"}
    ]
  end
end
