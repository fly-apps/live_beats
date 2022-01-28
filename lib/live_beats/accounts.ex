defmodule LiveBeats.Accounts do
  import Ecto.Query
  import Ecto.Changeset

  alias LiveBeats.Repo
  alias LiveBeats.Accounts.{User, Identity, Events}

  @pubsub LiveBeats.PubSub

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(@pubsub, topic(user_id))
  end

  def unsubscribe(user_id) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(user_id))
  end

  defp topic(user_id), do: "user:#{user_id}"

  def list_users(opts) do
    Repo.replica().all(from u in User, limit: ^Keyword.fetch!(opts, :limit))
  end

  def get_users_map(user_ids) when is_list(user_ids) do
    Repo.replica().all(from u in User, where: u.id in ^user_ids, select: {u.id, u})
  end

  def lists_users_by_active_profile(id, opts) do
    Repo.replica().all(
      from u in User, where: u.active_profile_user_id == ^id, limit: ^Keyword.fetch!(opts, :limit)
    )
  end

  def admin?(%User{} = user) do
    user.email in LiveBeats.config([:admin_emails])
  end

  @doc """
  Updates a user public's settings and exectes event.
  """
  def update_public_settings(%User{} = user, attrs) do
    user
    |> change_settings(attrs)
    |> Repo.update()
    |> case do
      {:ok, new_user} ->
        LiveBeats.execute(__MODULE__, %Events.PublicSettingsChanged{user: new_user})
        {:ok, new_user}

      {:error, _} = error ->
        error
    end
  end

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.replica().get!(User, id)

  def get_user(id), do: Repo.replica().get(User, id)

  def get_user_by!(fields), do: Repo.replica().get_by!(User, fields)

  def update_active_profile(%User{active_profile_user_id: same_id} = current_user, same_id) do
    current_user
  end

  def update_active_profile(%User{} = current_user, profile_uid) do
    {1, _} =
      Repo.update_all(from(u in User, where: u.id == ^current_user.id),
        set: [active_profile_user_id: profile_uid]
      )

    broadcast!(
      current_user,
      %Events.ActiveProfileChanged{current_user: current_user, new_profile_user_id: profile_uid}
    )

    %User{current_user | active_profile_user_id: profile_uid}
  end

  ## User registration

  @doc """
  Registers a user from their GithHub information.
  """
  def register_github_user(primary_email, info, emails, token) do
    if user = get_user_by_provider(:github, primary_email) do
      update_github_token(user, token)
    else
      info
      |> User.github_registration_changeset(primary_email, emails, token)
      |> Repo.insert()
    end
  end

  def get_user_by_provider(provider, email) when provider in [:github] do
    query =
      from(u in User,
        join: i in assoc(u, :identities),
        where:
          i.provider == ^to_string(provider) and
            fragment("lower(?)", u.email) == ^String.downcase(email)
      )

    Repo.one(query)
  end

  def change_settings(%User{} = user, attrs) do
    User.settings_changeset(user, attrs)
  end

  defp update_github_token(%User{} = user, new_token) do
    identity =
      Repo.one!(from(i in Identity, where: i.user_id == ^user.id and i.provider == "github"))

    {:ok, _} =
      identity
      |> change()
      |> put_change(:provider_token, new_token)
      |> Repo.update()

    {:ok, Repo.preload(user, :identities, force: true)}
  end

  defp broadcast!(%User{} = user, msg) do
    Phoenix.PubSub.broadcast!(@pubsub, topic(user.id), {__MODULE__, msg})
  end
end
