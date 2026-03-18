defmodule Ink.CodeBlocks.CodeBlock do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "code_blocks" do
    field :room_id, :binary_id
    field :language, :string, default: "javascript"
    field :code, :string, default: ""
    field :output, :string
    field :name, :string
    field :x, :float, default: 0.0
    field :y, :float, default: 0.0
    field :width, :integer, default: 400
    field :z_index, :integer, default: 0

    timestamps(type: :utc_datetime_usec)
  end

  @valid_languages ["javascript", "python", "plain_text"]

  def languages, do: @valid_languages

  def templates do
    %{
      "javascript" => "console.log(\"Hello, World!\");",
      "python" => "print(\"Hello, World!\")",
      "plain_text" => ""
    }
  end

  def changeset(code_block, attrs) do
    code_block
    |> cast(attrs, [:room_id, :language, :code, :output, :name, :x, :y, :width, :z_index])
    |> validate_required([:room_id, :language])
    |> validate_inclusion(:language, @valid_languages)
  end

  def create_changeset(attrs) do
    language = Map.get(attrs, "language", "javascript") |> normalize_language()
    template = Map.get(templates(), language, "")

    %__MODULE__{}
    |> cast(attrs, [:room_id, :language, :code, :output, :name, :x, :y, :width, :z_index])
    |> put_change(:language, language)
    |> put_change(:code, Map.get(attrs, "code", template))
    |> validate_required([:room_id])
    |> validate_inclusion(:language, @valid_languages)
  end

  defp normalize_language("js"), do: "javascript"
  defp normalize_language("python"), do: "python"
  defp normalize_language("plain_text"), do: "plain_text"
  defp normalize_language(lang) when lang in @valid_languages, do: lang
  defp normalize_language(_), do: "javascript"
end
