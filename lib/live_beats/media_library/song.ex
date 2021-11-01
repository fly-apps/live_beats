defmodule LiveBeats.MediaLibrary.Song do
  use Ecto.Schema
  import Ecto.Changeset

  schema "songs" do
    field :album_artist, :string
    field :artist, :string
    field :date_recorded, :naive_datetime
    field :date_released, :naive_datetime
    field :duration, :integer
    field :title, :string
    field :mp3_path, :string
    field :mp3_filename, :string
    belongs_to :user, LiveBeats.Accounts.User
    belongs_to :genre, LiveBeats.MediaLibrary.Genre

    timestamps()
  end

  @doc false
  def changeset(song, attrs) do
    song
    |> cast(attrs, [:album_artist, :artist, :title, :date_recorded, :date_released])
    |> validate_required([:artist, :title])
  end

  def put_mp3_path(%Ecto.Changeset{} = changeset) do
    if changeset.valid? do
      filename = Ecto.UUID.generate() <> ".mp3"

      changeset
      |> Ecto.Changeset.put_change(:mp3_filename, filename)
      |> Ecto.Changeset.put_change(:mp3_path, "priv/static/uploads/songs/#{filename}")
    else
      changeset
    end
  end
end
