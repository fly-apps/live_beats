defmodule LiveBeats.MediaLibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveBeats.MediaLibrary` context.
  """

  @doc """
  Generate a song.
  """
  def song_fixture(attrs \\ %{}) do
    {:ok, song} =
      attrs
      |> Enum.into(%{
        album_artist: "some album_artist",
        artist: "some artist",
        date_recorded: ~N[2021-10-26 20:11:00],
        date_released: ~N[2021-10-26 20:11:00],
        duration: 42,
        title: "some title"
      })
      |> LiveBeats.MediaLibrary.create_song()

    song
  end
end
