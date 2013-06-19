defmodule Migrations.Mixfile do
  use Mix.Project

  def project do
    [ app: :exmig,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  defp deps do
    deps(Mix.env)
  end
  defp deps(:test) do
   [
     {:epgsql, github: "wg/epgsql"},
   ]
  end
  defp deps(_), do: []
end
