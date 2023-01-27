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
    field :status, Ecto.Enum, values: [stopped: 1, playing: 2, paused: 3], default: :stopped
    field :title, :string
    field :attribution, :string
    field :mp3_url, :string
    field :mp3_filepath, :string
    field :mp3_filename, :string
    field :mp3_filesize, :integer, default: 0
    field :server_ip, EctoNetwork.INET
    field :position, :integer, default: 0
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
    |> cast(attrs, [:album_artist, :artist, :title, :attribution, :date_recorded, :date_released])
    |> validate_required([:artist, :title])
    |> unique_constraint(:title,
      message: "is a duplicated from another song",
      name: "songs_user_id_title_artist_index"
    )
  end

  def put_user(%Ecto.Changeset{} = changeset, %Accounts.User{} = user) do
    put_assoc(changeset, :user, user)
  end

  def put_stats(%Ecto.Changeset{} = changeset, %LiveBeats.MP3Stat{} = stat) do
    changeset
    |> put_duration(stat.duration)
    |> Ecto.Changeset.put_change(:mp3_filesize, stat.size)
  end

  defp put_duration(%Ecto.Changeset{} = changeset, duration) when is_integer(duration) do
    changeset
    |> Ecto.Changeset.change(%{duration: duration})
    |> Ecto.Changeset.validate_number(:duration,
      greater_than: 0,
      less_than: 1200,
      message: "must be less than 20 minutes"
    )
  end

  def put_mp3_path(%Ecto.Changeset{} = changeset) do
    if changeset.valid? do
      filename = Ecto.UUID.generate() <> ".mp3"
      filepath = LiveBeats.MediaLibrary.local_filepath(filename)

      changeset
      |> Ecto.Changeset.put_change(:mp3_filename, filename)
      |> Ecto.Changeset.put_change(:mp3_filepath, filepath)
      |> Ecto.Changeset.put_change(:mp3_url, mp3_url(filename))
    else
      changeset
    end
  end

  def put_server_ip(%Ecto.Changeset{} = changeset) do
    server_ip = LiveBeats.config([:files, :server_ip])
    Ecto.Changeset.cast(changeset, %{server_ip: server_ip}, [:server_ip])
  end

  defp mp3_url(filename) do
    %{scheme: scheme, host: host, port: port} = Enum.into(LiveBeats.config([:files, :host]), %{})
    URI.to_string(%URI{scheme: scheme, host: host, port: port, path: "/files/#{filename}"})
  end
end
