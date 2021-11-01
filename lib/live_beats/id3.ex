defmodule LiveBeats.ID3 do
  alias LiveBeats.ID3

  defstruct title: nil,
            artist: nil,
            album: nil,
            year: nil

  def parse(path) do
    binary = File.read!(path)
    size = byte_size(binary) - 128
    <<_::binary-size(size), id3_tag::binary>> = binary

    case id3_tag do
      <<
        "TAG",
        title::binary-size(30),
        artist::binary-size(30),
        album::binary-size(30),
        year::binary-size(4),
        _comment::binary-size(30),
        _rest::binary
      >> ->
        {:ok,
         %ID3{
           title: strip(title),
           artist: strip(artist),
           album: strip(album),
           year: year
         }}

      _invalid ->
        {:error, :invalid}
    end
  end

  defp strip(binary), do: String.trim_trailing(binary, <<0>>)
end
