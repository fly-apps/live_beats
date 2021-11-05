defmodule LiveBeats.MediaLibrary.Song do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveBeats.MediaLibrary.Song
  alias LiveBeats.Accounts

  schema "songs" do
    field :album_artist, :string
    field :artist, :string
    field :played_at, :utc_datetime
    field :paused_at, :utc_datetime
    field :date_recorded, :naive_datetime
    field :date_released, :naive_datetime
    field :duration, :integer
    field :status, Ecto.Enum, values: [stopped: 1, playing: 2, paused: 3]
    field :title, :string
    field :mp3_path, :string
    field :mp3_filepath, :string
    belongs_to :user, Accounts.User
    belongs_to :genre, LiveBeats.MediaLibrary.Genre

    timestamps()
  end

  def playing?(%Song{} = song), do: song.status == :playing
  def paused?(%Song{} = song), do: song.status == :paused
  def stopped?(%Song{} = song), do: song.status == :stopped

  @doc false
  def changeset(song, attrs) do
    song
    |> cast(attrs, [:album_artist, :artist, :title, :date_recorded, :date_released])
    |> validate_required([:artist, :title])
    |> validate_number(:duration, greater_than: 0, less_than: 1200)
  end

  def put_user(%Ecto.Changeset{} = changeset, %Accounts.User{} = user) do
    put_assoc(changeset, :user, user)
  end

  def put_mp3_path(%Ecto.Changeset{} = changeset) do
    if changeset.valid? do
      filename = Ecto.UUID.generate() <> ".mp3"
      filepath = Path.join("priv/static/uploads/songs", filename)

      changeset
      |> Ecto.Changeset.put_change(:mp3_filepath, filepath)
      |> Ecto.Changeset.put_change(:mp3_path, Path.join("uploads/songs", filename))
    else
      changeset
    end
  end
end
