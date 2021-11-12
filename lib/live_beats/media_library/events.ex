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
end
