defmodule LiveBeats.MediaLibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveBeats.MediaLibrary` context.
  """

  alias LiveBeats.MediaLibrary.Song

  @doc """
  Generate a song.
  """
  def song_fixture(attrs \\ %{}) do
    {:ok, server_ip} = EctoNetwork.INET.cast(LiveBeats.config([:files, :server_ip]))

    {:ok, song} =
      struct!(
        Song,
        Enum.into(attrs, %{
          album_artist: "some album_artist",
          artist: "some artist",
          date_recorded: ~N[2021-10-26 20:11:00],
          date_released: ~N[2021-10-26 20:11:00],
          duration: 42,
          title: "some title",
          mp3_url: "//example.com/mp3.mp3",
          mp3_filename: "mp3.mp3",
          mp3_filepath: "/data/mp3.mp3",
          server_ip: server_ip,
          status: :stopped
        })
      )
      |> LiveBeats.Repo.insert()

    song
  end
end
