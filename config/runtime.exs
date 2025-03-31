import Config

app_name = :shortcut_automation

config :logger,
  level: System.get_env("LOGGER_LEVEL", "info") |> String.to_existing_atom()

shortcut_base_url =
  System.get_env("SHORTCUT_BASE_URL") ||
    raise """
    environment variable SHORTCUT_BASE_URL is missing.
    For example: http://api.example.com
    """

shortcut_org_name =
  System.get_env("SHORTCUT_ORG_NAME") ||
    raise """
    environment variable SHORTCUT_ORG_NAME is missing.
    For example: tomate-example
    """

shortcut_project_ids =
  System.get_env("SHORTCUT_PROJECT_IDS") ||
    raise """
    environment variable SHORTCUT_PROJECT_IDS is missing.
    For example: 41,16294
    """

shortcut_workflow_id =
  System.get_env("SHORTCUT_WORKFLOW_ID") ||
    raise """
    environment variable SHORTCUT_WORKFLOW_ID is missing.
    For example: 500000026
    """

config app_name,
  base_url: shortcut_base_url,
  org_name: shortcut_org_name,
  project_ids:
    shortcut_project_ids
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1),
  workflow_id: String.to_integer(shortcut_workflow_id)

case config_env() do
  :test ->
    config app_name,
      api_token: "test_token"

  :dev ->
    shortcut_api_token =
      System.get_env("SHORTCUT_API_TOKEN") ||
        raise """
        environment variable SHORTCUT_API_TOKEN is missing.
        For example: sk-xyz123...
        """

    config app_name, api_token: shortcut_api_token

  :prod ->
    config app_name, api_token: System.fetch_env!("SHORTCUT_API_TOKEN")
end
