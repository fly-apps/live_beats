defmodule LiveBeats.MediaLibrary.Events do
  defmodule Play do
    defstruct song: nil, elapsed: nil
  end

  defmodule Pause do
    defstruct song: nil
  end

  defmodule PublicProfileUpdated do
    defstruct profile: nil
  end

  defmodule SongsImported do
    defstruct user_id: nil, songs: []
  end

  defmodule NewPosition do
    defstruct song: nil
  end

  defmodule SongDeleted do
    defstruct song: nil
  end

  defmodule SpeechToText do
    defstruct song_id: nil, segment: nil
  end
end
