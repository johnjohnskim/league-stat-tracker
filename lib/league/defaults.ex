defmodule League.Defaults do
  @moduledoc """
  Defines any default config settings for the League application, e.g. the
  default summoner or the default queue.
  """

  @doc """
  Fetches the default summoner we should use if no summoner is given.
  """
  def fetch_default_summoner! do
    Application.fetch_env!(:league, :default_summoner)
  end

  @doc """
  Fetches the default queue we should use if no queue is given.
  """
  def fetch_default_queue! do
    Application.fetch_env!(:league, :default_queue)
  end
end
