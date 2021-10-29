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
    belongs_to :user, LiveBeats.Accounts.User
    belongs_to :genre, LiveBeats.MediaLibrary.Genre

    timestamps()
  end

  @doc false
  def changeset(song, attrs) do
    song
    |> cast(attrs, [:album_artist, :artist, :duration, :title, :date_recorded, :date_released])
    |> validate_required([:artist, :duration, :title])
  end
end
