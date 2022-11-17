defmodule LiveBeats.MP3Stat do
  @moduledoc """
  Decodes MP3s and parses out information.

  MP3 decoding and duration calculation credit to:
  https://shadowfacts.net/2021/mp3-duration/
  """
  import Bitwise
  alias LiveBeats.MP3Stat

  defstruct duration: 0, size: 0, path: nil, title: nil, artist: nil, tags: nil

  @declared_frame_ids ~w(AENC APIC ASPI COMM COMR ENCR EQU2 ETCO GEOB GRID LINK MCDI MLLT OWNE PRIV PCNT POPM POSS RBUF RVA2 RVRB SEEK SIGN SYLT SYTC TALB TBPM TCOM TCON TCOP TDEN TDLY TDOR TDRC TDRL TDTG TENC TEXT TFLT TIPL TIT1 TIT2 TIT3 TKEY TLAN TLEN TMCL TMED TMOO TOAL TOFN TOLY TOPE TOWN TPE1 TPE2 TPE3 TPE4 TPOS TPRO TPUB TRCK TRSN TRSO TSOA TSOP TSOT TSRC TSSE TSST TXXX UFID USER USLT WCOM WCOP WOAF WOAR WOAS WORS WPAY WPUB WXXX)

  @v1_l1_bitrates {:invalid, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448,
                   :invalid}
  @v1_l2_bitrates {:invalid, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384,
                   :invalid}
  @v1_l3_bitrates {:invalid, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320,
                   :invalid}
  @v2_l1_bitrates {:invalid, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256,
                   :invalid}
  @v2_l2_l3_bitrates {:invalid, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160,
                      :invalid}

  def to_mmss(duration) when is_integer(duration) do
    hours = div(duration, 60 * 60)
    minutes = div(duration - hours * 60 * 60, 60)
    seconds = rem(duration - hours * 60 * 60 - minutes * 60, 60)

    [minutes, seconds]
    |> Enum.map(fn count -> String.pad_leading("#{count}", 2, ["0"]) end)
    |> Enum.join(":")
  end

  def parse(path) do
    stat = File.stat!(path)
    {tag_info, rest} = parse_tag(File.read!(path))
    duration = parse_frame(rest, 0, 0, 0)

    case duration do
      duration when is_float(duration) and duration > 0 ->
        title = Enum.at(tag_info["TIT2"] || [], 0)
        artist = Enum.at(tag_info["TPE1"] || [], 0)
        seconds = round(duration)

        {:ok,
         %MP3Stat{
           duration: seconds,
           size: stat.size,
           path: path,
           tags: tag_info,
           title: title,
           artist: artist
         }}

      _other ->
        {:error, :bad_file}
    end
  rescue
    _ -> {:error, :bad_file}
  end

  defp parse_tag(<<
         "ID3",
         major_version::integer,
         _revision::integer,
         _unsynchronized::size(1),
         extended_header::size(1),
         _experimental::size(1),
         _footer::size(1),
         0::size(4),
         tag_size_synchsafe::binary-size(4),
         rest::binary
       >>) do
    tag_size = decode_synchsafe_integer(tag_size_synchsafe)

    {rest, ext_header_size} =
      if extended_header == 1 do
        skip_extended_header(major_version, rest)
      else
        {rest, 0}
      end

    parse_frames(major_version, rest, tag_size - ext_header_size, [])
  end

  defp parse_tag(<<
         _first::integer,
         _second::integer,
         _third::integer,
         rest::binary
       >>) do
    # has no ID3
    {%{}, rest}
  end

  defp parse_tag(_), do: {%{}, ""}

  defp decode_synchsafe_integer(<<bin>>), do: bin

  defp decode_synchsafe_integer(binary) do
    binary
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce(0, fn {el, index}, acc -> acc ||| el <<< (index * 7) end)
  end

  defp skip_extended_header(3, <<
         ext_header_size::size(32),
         _flags::size(16),
         _padding_size::size(32),
         rest::binary
       >>) do
    remaining_ext_header_size = ext_header_size - 6
    <<_::binary-size(remaining_ext_header_size), rest::binary>> = rest
    {rest, ext_header_size}
  end

  defp skip_extended_header(4, <<
         ext_header_size_synchsafe::size(32),
         1::size(8),
         _flags::size(8),
         rest::binary
       >>) do
    ext_header_size = decode_synchsafe_integer(ext_header_size_synchsafe)
    remaining_ext_header_size = ext_header_size - 6
    <<_::binary-size(remaining_ext_header_size), rest::binary>> = rest
    {rest, ext_header_size}
  end

  defp parse_frames(_, data, tag_length_remaining, frames)
       when tag_length_remaining <= 0 do
    {Map.new(frames), data}
  end

  defp parse_frames(
         major_version,
         <<
           frame_id::binary-size(4),
           frame_size_maybe_synchsafe::binary-size(4),
           0::size(1),
           _tag_alter_preservation::size(1),
           _file_alter_preservation::size(1),
           _read_only::size(1),
           0::size(4),
           _grouping_identity::size(1),
           0::size(2),
           _compression::size(1),
           _encryption::size(1),
           _unsynchronized::size(1),
           _has_data_length_indicator::size(1),
           _unused::size(1),
           rest::binary
         >>,
         tag_length_remaining,
         frames
       ) do
    frame_size =
      case major_version do
        4 ->
          decode_synchsafe_integer(frame_size_maybe_synchsafe)

        3 ->
          <<size::size(32)>> = frame_size_maybe_synchsafe
          size
      end

    total_frame_size = frame_size + 10
    next_tag_length_remaining = tag_length_remaining - total_frame_size

    result = decode_frame(frame_id, frame_size, rest)

    case result do
      {nil, rest, :halt} ->
        {Map.new(frames), rest}

      {nil, rest, :cont} ->
        parse_frames(major_version, rest, next_tag_length_remaining, frames)

      {new_frame, rest} ->
        parse_frames(major_version, rest, next_tag_length_remaining, [new_frame | frames])
    end
  end

  defp parse_frames(_, data, _, frames) do
    {Map.new(frames), data}
  end

  defp decode_frame("TXXX", frame_size, <<text_encoding::size(8), rest::binary>>) do
    {description, desc_size, rest} = decode_string(text_encoding, frame_size - 1, rest)
    {value, _, rest} = decode_string(text_encoding, frame_size - 1 - desc_size, rest)
    {{"TXXX", {description, value}}, rest}
  end

  defp decode_frame(
         "COMM",
         frame_size,
         <<text_encoding::size(8), language::binary-size(3), rest::binary>>
       ) do
    {short_desc, desc_size, rest} = decode_string(text_encoding, frame_size - 4, rest)
    {value, _, rest} = decode_string(text_encoding, frame_size - 4 - desc_size, rest)
    {{"COMM", {language, short_desc, value}}, rest}
  end

  defp decode_frame("APIC", frame_size, <<text_encoding::size(8), rest::binary>>) do
    {mime_type, mime_len, rest} = decode_string(0, frame_size - 1, rest)

    <<picture_type::size(8), rest::binary>> = rest

    {description, desc_len, rest} =
      decode_string(text_encoding, frame_size - 1 - mime_len - 1, rest)

    image_data_size = frame_size - 1 - mime_len - 1 - desc_len
    {image_data, rest} = :erlang.split_binary(rest, image_data_size)

    {{"APIC", {mime_type, picture_type, description, image_data}}, rest}
  end

  defp decode_frame(id, frame_size, rest) do
    cond do
      Regex.match?(~r/^T[0-9A-Z]+$/, id) ->
        decode_text_frame(id, frame_size, rest)

      id in @declared_frame_ids ->
        <<_frame_data::binary-size(frame_size), rest::binary>> = rest
        {nil, rest, :cont}

      true ->
        {nil, rest, :halt}
    end
  end

  defp decode_text_frame(id, frame_size, <<text_encoding::size(8), rest::binary>>) do
    {strs, rest} = decode_string_sequence(text_encoding, frame_size - 1, rest)
    {{id, strs}, rest}
  end

  defp decode_string_sequence(encoding, max_byte_size, data, acc \\ [])

  defp decode_string_sequence(_, max_byte_size, data, acc) when max_byte_size <= 0 do
    {Enum.reverse(acc), data}
  end

  defp decode_string_sequence(encoding, max_byte_size, data, acc) do
    {str, str_size, rest} = decode_string(encoding, max_byte_size, data)
    decode_string_sequence(encoding, max_byte_size - str_size, rest, [str | acc])
  end

  defp convert_string(encoding, str) when encoding in [0, 3] do
    str
  end

  defp convert_string(1, data) do
    {encoding, bom_length} = :unicode.bom_to_encoding(data)
    {_, string_data} = String.split_at(data, bom_length)
    :unicode.characters_to_binary(string_data, encoding)
  end

  defp convert_string(2, data) do
    :unicode.characters_to_binary(data, {:utf16, :big})
  end

  defp decode_string(encoding, max_byte_size, data) when encoding in [1, 2] do
    {str, rest} = get_double_null_terminated(data, max_byte_size)

    {convert_string(encoding, str), byte_size(str) + 2, rest}
  end

  defp decode_string(encoding, max_byte_size, data) when encoding in [0, 3] do
    case :binary.split(data, <<0>>) do
      [str, rest] when byte_size(str) + 1 <= max_byte_size ->
        {str, byte_size(str) + 1, rest}

      _ ->
        {str, rest} = :erlang.split_binary(data, max_byte_size)
        {str, max_byte_size, rest}
    end
  end

  defp get_double_null_terminated(data, max_byte_size, acc \\ [])

  defp get_double_null_terminated(rest, 0, acc) do
    {acc |> Enum.reverse() |> :binary.list_to_bin(), rest}
  end

  defp get_double_null_terminated(<<0, 0, rest::binary>>, _, acc) do
    {acc |> Enum.reverse() |> :binary.list_to_bin(), rest}
  end

  defp get_double_null_terminated(<<a::size(8), b::size(8), rest::binary>>, max_byte_size, acc) do
    next_max_byte_size = max_byte_size - 2
    get_double_null_terminated(rest, next_max_byte_size, [b, a | acc])
  end

  defp parse_frame(
         <<
           0xFF::size(8),
           0b111::size(3),
           version_bits::size(2),
           layer_bits::size(2),
           _protected::size(1),
           bitrate_index::size(4),
           sampling_rate_index::size(2),
           padding::size(1),
           _private::size(1),
           _channel_mode_index::size(2),
           _mode_extension::size(2),
           _copyright::size(1),
           _original::size(1),
           _emphasis::size(2),
           _rest::binary
         >> = data,
         acc,
         frame_count,
         offset
       ) do
    with version when version != :invalid <- lookup_version(version_bits),
         layer when layer != :invalid <- lookup_layer(layer_bits),
         sampling_rate when sampling_rate != :invalid <-
           lookup_sampling_rate(version, sampling_rate_index),
         bitrate when bitrate != :invalid <- lookup_bitrate(version, layer, bitrate_index) do
      samples = lookup_samples_per_frame(version, layer)
      frame_size = get_frame_size(samples, layer, bitrate, sampling_rate, padding)
      frame_duration = samples / sampling_rate
      <<_skipped::binary-size(frame_size), rest::binary>> = data
      parse_frame(rest, acc + frame_duration, frame_count + 1, offset + frame_size)
    else
      _ ->
        <<_::size(8), rest::binary>> = data
        parse_frame(rest, acc, frame_count, offset + 1)
    end
  end

  defp parse_frame(<<_::size(8), rest::binary>>, acc, frame_count, offset) do
    parse_frame(rest, acc, frame_count, offset + 1)
  end

  defp parse_frame(<<>>, acc, _frame_count, _offset) do
    acc
  end

  defp lookup_version(0b00), do: :version25
  defp lookup_version(0b01), do: :invalid
  defp lookup_version(0b10), do: :version2
  defp lookup_version(0b11), do: :version1

  defp lookup_layer(0b00), do: :invalid
  defp lookup_layer(0b01), do: :layer3
  defp lookup_layer(0b10), do: :layer2
  defp lookup_layer(0b11), do: :layer1

  defp lookup_sampling_rate(_version, 0b11), do: :invalid
  defp lookup_sampling_rate(:version1, 0b00), do: 44100
  defp lookup_sampling_rate(:version1, 0b01), do: 48000
  defp lookup_sampling_rate(:version1, 0b10), do: 32000
  defp lookup_sampling_rate(:version2, 0b00), do: 22050
  defp lookup_sampling_rate(:version2, 0b01), do: 24000
  defp lookup_sampling_rate(:version2, 0b10), do: 16000
  defp lookup_sampling_rate(:version25, 0b00), do: 11025
  defp lookup_sampling_rate(:version25, 0b01), do: 12000
  defp lookup_sampling_rate(:version25, 0b10), do: 8000

  defp lookup_bitrate(_version, _layer, 0), do: :invalid
  defp lookup_bitrate(_version, _layer, 0xF), do: :invalid
  defp lookup_bitrate(:version1, :layer1, index), do: elem(@v1_l1_bitrates, index)
  defp lookup_bitrate(:version1, :layer2, index), do: elem(@v1_l2_bitrates, index)
  defp lookup_bitrate(:version1, :layer3, index), do: elem(@v1_l3_bitrates, index)

  defp lookup_bitrate(v, :layer1, index) when v in [:version2, :version25],
    do: elem(@v2_l1_bitrates, index)

  defp lookup_bitrate(v, l, index) when v in [:version2, :version25] and l in [:layer2, :layer3],
    do: elem(@v2_l2_l3_bitrates, index)

  defp lookup_samples_per_frame(:version1, :layer1), do: 384
  defp lookup_samples_per_frame(:version1, :layer2), do: 1152
  defp lookup_samples_per_frame(:version1, :layer3), do: 1152
  defp lookup_samples_per_frame(v, :layer1) when v in [:version2, :version25], do: 384
  defp lookup_samples_per_frame(v, :layer2) when v in [:version2, :version25], do: 1152
  defp lookup_samples_per_frame(v, :layer3) when v in [:version2, :version25], do: 576

  defp get_frame_size(samples, layer, kbps, sampling_rate, padding) do
    sample_duration = 1 / sampling_rate
    frame_duration = samples * sample_duration
    bytes_per_second = kbps * 1000 / 8
    size = floor(frame_duration * bytes_per_second)

    if padding == 1 do
      size + lookup_slot_size(layer)
    else
      size
    end
  end

  defp lookup_slot_size(:layer1), do: 4
  defp lookup_slot_size(l) when l in [:layer2, :layer3], do: 1
end
