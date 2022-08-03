defmodule LiveBeatsWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    error(%{errors: form.errors, field: field, input_name: input_name(form, field)})
  end

  def error(%{errors: errors, field: field} = assigns) do
    assigns =
      assigns
      |> assign(:error_values, Keyword.get_values(errors, field))
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <%= for error <- @error_values do %>
      <span
        phx-feedback-for={@input_name}
        class={
          "invalid-feedback inline-block pl-2 pr-2 text-sm text-white bg-red-600 rounded-md #{@class}"
        }
      >
        <%= translate_error(error) %>
      </span>
    <% end %>

    <%= if Enum.empty?(@error_values) do %>
      <span class={"invalid-feedback inline-block h-0 #{@class}"}></span>
    <% end %>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(LiveBeatsWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(LiveBeatsWeb.Gettext, "errors", msg, opts)
    end
  end

  def translate_changeset_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {key, value} -> "#{key} #{translate_error(value)}" end)
    |> Enum.join("\n")
  end
end
