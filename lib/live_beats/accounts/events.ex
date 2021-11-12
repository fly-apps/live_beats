defmodule LiveBeats.Accounts.Events do
  defmodule ActiveProfileChanged do
    defstruct current_user: nil, new_profile_user_id: nil
  end

  defmodule PublicSettingsChanged do
    defstruct user: nil
  end
end
