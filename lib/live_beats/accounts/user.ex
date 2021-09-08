defmodule LiveBeats.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveBeats.Accounts.{User, Identity}

  schema "users" do
    field :email, :string
    field :name, :string
    field :username, :string
    field :confirmed_at, :naive_datetime
    field :role, :string, default: "subscriber"

    has_many :identities, Identity

    timestamps()
  end

  @doc """
  A user changeset for github registration.
  """
  def github_registration_changeset(info, primary_email, emails, token) do
    %{"login" => username} = info
    identity_changeset = Identity.github_registration_changeset(info, primary_email, emails, token)
    if identity_changeset.valid? do
      params = %{
        "username" => username,
        "email" => primary_email,
        "name" => get_change(identity_changeset, :provider_name),
      }
      %User{}
      |> cast(params, [:email, :name, :username])
      |> validate_required([:email, :name, :username])
      |> validate_email()
      |> put_assoc(:identities, [identity_changeset])
    else
      %User{}
      |> change()
      |> Map.put(:value?, false)
      |> put_assoc(:identities, [identity_changeset])
    end
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, LiveBeats.Repo)
    |> unique_constraint(:email)
  end
end
