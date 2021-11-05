defmodule LiveBeats.ID3 do
  alias LiveBeats.ID3

  defstruct title: nil,
            artist: nil,
            album: nil,
            year: nil

  def parse(path) do
    with {:ok, parsed} <- :id3_tag_reader.read_tag(path) do
      {:ok, parsed}
        # %ID3{
        #   title: strip(title),
        #   artist: strip(artist),
        #   album: strip(album),
        #   year: 2028
        # }}
    else
      other ->
        {:error, other}
    end
  end

  defp strip(binary), do: String.trim_trailing(binary, <<0>>)
end
