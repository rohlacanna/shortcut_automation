defmodule ShortcutAutomation do
  @moduledoc """
  Module for automating tasks related to Shortcut (project management tool).
  Generates release reports based on stories in validation status.
  """

  @type date_info :: %{day: integer(), month: String.t(), year: integer()}
  @type story :: %{required(String.t()) => any()}
  @type readme_result :: {String.t(), String.t()} | String.t()

  @doc """
  Generates a readme for the release with stories that are in validation status.

  ## Parameters
    * `project_ids` - List of project IDs (default: from config)
    * `save_to_file` - Indicates if the result should be saved to a file (default: true)

  ## Returns
    * `{filename, content}` - If saved to file
    * `content` - If not saved to file
    * Error message in case of failure
  """
  @spec generate_release_readme(list(integer()) | nil, boolean()) :: readme_result | String.t()
  def generate_release_readme(custom_project_ids \\ nil, save_to_file \\ true) do
    with current_date <- Date.utc_today(),
         date_info <- get_formatted_date(current_date),
         {:ok, validation_state_id} <- find_validation_state_id(),
         stories <- fetch_stories_from_projects(custom_project_ids || project_ids()),
         filtered_stories <- filter_validation_stories(stories, validation_state_id) do
      generate_readme(filtered_stories, date_info, save_to_file)
    else
      {:error, message} -> message
    end
  end

  defp get_formatted_date(date) do
    %{
      day: date.day,
      month: translate_month(date.month),
      year: date.year
    }
  end

  defp translate_month(month) do
    %{
      1 => "janeiro",
      2 => "fevereiro",
      3 => "março",
      4 => "abril",
      5 => "maio",
      6 => "junho",
      7 => "julho",
      8 => "agosto",
      9 => "setembro",
      10 => "outubro",
      11 => "novembro",
      12 => "dezembro"
    }[month]
  end

  defp find_validation_state_id do
    case get_request("workflows/#{workflow_id()}") do
      {:ok, workflow} ->
        validation_state =
          workflow["states"]
          |> Enum.find(fn state ->
            state["name"] |> String.downcase() |> String.contains?("validação")
          end)

        case validation_state do
          nil -> {:error, "Estado 'Em validação' não encontrado no workflow."}
          state -> {:ok, state["id"]}
        end

      {:error, reason} ->
        {:error, "Erro ao buscar workflow: #{inspect(reason)}"}
    end
  end

  defp fetch_stories_from_projects(project_ids) do
    IO.puts("Buscando histórias dos projetos: #{inspect(project_ids)}")

    project_ids
    |> Task.async_stream(
      fn project_id -> fetch_stories_for_project(project_id) end,
      timeout: 10_000,
      ordered: false
    )
    |> Enum.flat_map(fn
      {:ok, stories} -> stories
      _ -> []
    end)
    |> tap(fn stories -> IO.puts("Total de histórias encontradas: #{length(stories)}") end)
  end

  defp fetch_stories_for_project(project_id) do
    case get_request("projects/#{project_id}/stories") do
      {:ok, stories} ->
        IO.puts("Encontradas #{length(stories)} histórias no projeto #{project_id}")
        stories

      {:error, reason} ->
        IO.puts("Erro ao buscar histórias do projeto #{project_id}: #{inspect(reason)}")
        []
    end
  end

  defp filter_validation_stories(stories, validation_state_id) do
    filtered =
      stories
      |> Enum.filter(fn story ->
        story["workflow_state_id"] == validation_state_id && story["archived"] != true
      end)

    IO.puts("Histórias em validação (não arquivadas): #{length(filtered)}")
    filtered
  end

  defp generate_readme(stories, date_info, save_to_file) do
    table = generate_stories_table(stories)

    readme_content = """
    ### Descrição:
    Funcionalidades que vão entrar na release #{date_info.day} de #{date_info.month} de #{date_info.year}:

    ### Stories:

    #{table}

    ### Total
    Vão entrar #{Enum.count(stories)} features novas.
    """

    if save_to_file do
      save_readme_to_file(readme_content, date_info)
    else
      readme_content
    end
  end

  defp generate_stories_table([]),
    do: "Nenhuma história encontrada na coluna 'em validação' para os projetos Web."

  defp generate_stories_table(stories) do
    header = "| ID | NOME | LINK |\n|-----|------|------|\n"

    rows =
      stories
      |> Enum.map_join("\n", fn story ->
        id = story["id"]
        name = story["name"] |> to_string() |> String.replace("|", "\\|")
        link = "https://app.shortcut.com/#{org_name()}/story/#{id}"
        "| #{id} | #{name} | #{link} |"
      end)

    header <> rows
  end

  defp save_readme_to_file(content, date_info) do
    filename = "release_#{date_info.day}_#{date_info.month}_#{date_info.year}.md"

    case File.write(filename, content) do
      :ok ->
        IO.puts("README gerado e salvo em #{filename}")
        {filename, content}

      {:error, reason} ->
        IO.puts("Erro ao salvar o arquivo: #{inspect(reason)}")
        content
    end
  end

  defp get_request(path) do
    url = "#{base_url()}/#{path}"

    case HTTPoison.get(url, headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, error} -> {:error, "Erro ao decodificar JSON: #{inspect(error)}"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Resposta com código de status inesperado: #{status_code}"}

      {:error, error} ->
        {:error, "Falha na requisição HTTP: #{inspect(error)}"}
    end
  end

  defp api_token, do: Application.fetch_env!(:shortcut_automation, :api_token)
  defp base_url, do: Application.fetch_env!(:shortcut_automation, :base_url)
  defp project_ids, do: Application.fetch_env!(:shortcut_automation, :project_ids)
  defp workflow_id, do: Application.fetch_env!(:shortcut_automation, :workflow_id)
  defp org_name, do: Application.fetch_env!(:shortcut_automation, :org_name)

  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Shortcut-Token", api_token()}
    ]
  end
end
