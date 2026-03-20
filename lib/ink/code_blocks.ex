defmodule Ink.CodeBlocks do
  import Ecto.Query
  alias Ink.CodeBlocks.CodeBlock
  alias Ink.Repo

  def get_code_block(id), do: Repo.get(CodeBlock, id)

  def get_code_blocks_by_room(room_id),
    do:
      Repo.all(
        from(cb in CodeBlock, where: cb.room_id == ^room_id, order_by: [asc: cb.inserted_at])
      )

  def create_code_block(attrs) do
    attrs
    |> CodeBlock.create_changeset()
    |> Repo.insert()
  end

  def update_code_block(%CodeBlock{} = code_block, attrs) do
    code_block
    |> CodeBlock.changeset(attrs)
    |> Repo.update()
  end

  def update_position(%CodeBlock{} = code_block, x, y) do
    code_block
    |> CodeBlock.changeset(%{x: x, y: y})
    |> Repo.update()
  end

  def update_content(%CodeBlock{} = code_block, code) do
    code_block
    |> CodeBlock.changeset(%{code: code})
    |> Repo.update()
  end

  def update_language(%CodeBlock{} = code_block, language) do
    normalized = normalize_language(language)
    templates = CodeBlock.templates()
    template = Map.get(templates, normalized, "")

    code_block
    |> CodeBlock.changeset(%{language: normalized, code: template, output: nil})
    |> Repo.update()
  end

  def update_output(%CodeBlock{} = code_block, output) do
    code_block
    |> CodeBlock.changeset(%{output: output})
    |> Repo.update()
  end

  def update_width(%CodeBlock{} = code_block, width) do
    code_block
    |> CodeBlock.changeset(%{width: width})
    |> Repo.update()
  end

  def delete_code_block(%CodeBlock{} = code_block), do: Repo.delete(code_block)

  def to_map(%CodeBlock{} = cb) do
    %{
      "id" => cb.id,
      "room_id" => cb.room_id,
      "language" => cb.language,
      "code" => cb.code,
      "output" => cb.output,
      "name" => cb.name,
      "x" => cb.x,
      "y" => cb.y,
      "width" => cb.width,
      "z_index" => cb.z_index,
      "inserted_at" => cb.inserted_at,
      "updated_at" => cb.updated_at
    }
  end

  defp normalize_language("js"), do: "javascript"
  defp normalize_language("python"), do: "python"
  defp normalize_language("plain_text"), do: "plain_text"
  defp normalize_language(lang) when lang in ["javascript", "python", "plain_text"], do: lang
  defp normalize_language(_), do: "javascript"
end
