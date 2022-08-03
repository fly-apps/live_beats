defmodule LiveBeats.MP3StatTest do
  use ExUnit.Case, async: true

  alias LiveBeats.MP3Stat

  test "parse/1 with valid mp3" do
    {:ok, %MP3Stat{} = stat} = MP3Stat.parse("test/support/fixtures/silence1s.mp3")
    assert stat.duration == 1
    assert stat.title == "Silence"
    assert stat.artist == "Anon"
  end

  test "parse/1 with invalid mp3" do
    assert {:error, :bad_file} = MP3Stat.parse("mix.exs")
  end

  test "parse/1 with missing file" do
    assert {:error, :bad_file} = MP3Stat.parse("lsfjslkfjslkfjs")
  end
end
