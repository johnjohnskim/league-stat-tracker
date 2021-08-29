defmodule League.Release do
  @moduledoc """
  Setup and helper functions to be run after a release, e.g. database migrations.
  """

  @app :league

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed do
    load_app()
    Application.ensure_all_started(@app)

    for repo <- repos() do
      do_seed(repo)
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end

  defp do_seed(repo) do
    repo
    |> priv_path("seeds.exs")
    |> Code.eval_file()
  end

  defp priv_path(repo, filename) do
    priv_dir =
      repo.config[:otp_app]
      |> :code.priv_dir()
      |> to_string()

    Path.join([priv_dir, "repo", filename])
  end
end
