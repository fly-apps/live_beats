defmodule LiveBeats.MediaLibrary.TextSegment do
  use Ecto.Schema

  embedded_schema do
    field :start_time, :float
    field :text, :string
  end
end
