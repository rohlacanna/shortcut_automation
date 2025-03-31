# ShortcutAutomation

Ferramenta para automação de tarefas relacionadas ao Shortcut, uma plataforma de gerenciamento de projetos. Gera relatórios de release baseados em histórias no status de validação.

## Funcionalidades

- Busca histórias em projetos específicos do Shortcut
- Filtra histórias que estão em status de validação
- Gera um relatório de release em formato Markdown com as histórias encontradas

## Configuração

A aplicação utiliza variáveis de ambiente para configuração. Configure as seguintes variáveis:

```bash
export SHORTCUT_API_TOKEN="seu-token-de-api"
export SHORTCUT_BASE_URL="base_url"
export SHORTCUT_PROJECT_IDS="prject_ids"
export SHORTCUT_WORKFLOW_ID="workflow_id"
export SHORTCUT_ORG_NAME="org_name"
```

## Uso

```elixir
# Gera relatório usando configuração padrão e salva em arquivo
ShortcutAutomation.generate_release_readme()

# Gera relatório para projetos específicos sem salvar em arquivo
ShortcutAutomation.generate_release_readme([41, 16294], false)

# Exemplo de saída (retorno da função ou conteúdo do arquivo gerado)
"""
### Descrição:
Funcionalidades que vão entrar na release 31 de março de 2025:

### Stories:

| ID | NOME | LINK |
|-----|------|------|
| 12345 | Implementar login com Google | https://app.shortcut.com/sua-org/story/12345 |
| 12346 | Corrigir bug na página de perfil | https://app.shortcut.com/sua-org/story/12346 |

### Total
Vão entrar 2 features novas.
"""
```

## Contribuição

Para contribuir com esse projeto maravilhoso, você:

1. Precisará criar um fork deste repositório
2. Criar um branch com o padrão: `feature/awesome-commit`
3. Criar seu conteúdo maravilhoso nesta branch
4. Criar um pull-request neste repositório lindo
5. Esperar a avaliação do mesmo

E tchadam! Tá pronto o sorvetinho ✨

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para mais detalhes.