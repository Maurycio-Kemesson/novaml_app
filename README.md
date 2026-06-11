# NOVAML App — Interface Desktop No-Code para Machine Learning Astronômico

Frontend desktop da plataforma NOVAML, construído com Flutter para Windows. Permite criar projetos, configurar datasets CSV astronômicos, selecionar algoritmos e treinar modelos de Machine Learning sem escrever código, comunicando-se com o backend FastAPI via HTTP local.

---

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) 3.22+
- Dart SDK 3.3+
- Visual Studio 2022 com workload **Desktop development with C++**
- Git
- Backend NOVAML rodando em `http://localhost:8000`

> Para verificar: `flutter doctor` — todos os itens relevantes para Windows devem estar marcados com ✓.

---

## Instalação

### 1. Clonar o repositório

```bash
git clone https://github.com/Maurycio-Kemesson/novaml-app.git
cd novaml-app
```

### 2. Instalar dependências

```bash
flutter pub get
```

### 3. Gerar código (Freezed + Riverpod + JSON)

```bash
dart run build_runner build --delete-conflicting-outputs
```

> Necessário apenas na primeira vez ou ao modificar modelos anotados com `@freezed` / `@riverpod`.

---

## Rodando a aplicação

### Pré-requisito: backend no ar

Certifique-se de que o backend FastAPI está rodando antes de abrir o app:

```bash
# No repositório do backend
uvicorn main:app --reload
```

### Iniciando o app

```bash
flutter run -d windows
```

A janela abre maximizada com resolução mínima de **1024 × 700**.

---

## Fluxo de uso

### Passo 1 — Criar um projeto

1. Na tela **Projects**, clique em **New Project** (botão no canto superior direito)
2. Preencha o nome do projeto no dialog e confirme
3. Clique no card do projeto criado para abri-lo

---

### Passo 2 — Configurar o Workspace

Ao abrir um projeto, você entra no **Workspace**. Configure três itens:

**Ingest Stellar Dataset**
- Clique na área de upload ou arraste um arquivo `.csv`
- O dataset é carregado localmente — nenhum dado é enviado para a internet

**Data Partitioning**
- Ajuste o slider para definir a proporção **Train / Test** (padrão: 80 / 20)

**Algorithm Selection**
- Escolha entre os algoritmos disponíveis no backend:
  - Regressão Linear
  - Árvore de Decisão

---

### Passo 3 — Selecionar colunas no Spectral Data Preview

Após carregar o CSV, a tabela **Spectral Data Preview** exibe as primeiras 10 linhas:

| Controle | Função |
|----------|--------|
| `USE` (checkbox) | Inclui/exclui a coluna do treinamento |
| `TRGT` (radio) | Define a coluna alvo (variável dependente) |

> Colunas de texto (não numéricas) são marcadas com ⚠️ — o scikit-learn não as processa. Desmarque `USE` nessas colunas.

---

### Passo 4 — Iniciar o treinamento

Clique em **Initiate Neural Training** na barra inferior do Workspace.

A tela de loading exibe o progresso enquanto o backend treina o modelo. Ao concluir, você é redirecionado automaticamente para a tela de resultados.

---

### Passo 5 — Analisar os resultados

A tela **Dashboard Results** exibe:
- Score de validação (Acurácia para classificação, R² para regressão)
- Gráficos de performance
- Predições vs. valores reais

---

## Seções da aplicação

| Seção | Descrição |
|-------|-----------|
| **Projects** | Gerenciamento de projetos (criar, abrir, excluir) |
| **Workspace** | Configuração do dataset, algoritmo e particionamento |
| **Dashboard** | Visão geral de todos os modelos treinados com métricas |
| **Models** | Lista de modelos salvos no backend com opção de exportar e deletar |
| **Monitoring** | Status do sistema (CPU, RAM) e conectividade com o backend |

---

## Estrutura do Projeto

```
lib/
├── app/
│   └── app.dart                   # raiz da aplicação (MaterialApp)
├── core/
│   ├── database/
│   │   └── app_database.dart      # SQLite local (sqflite_ffi)
│   ├── models/
│   │   └── api_models.dart        # modelos de dados da API (Freezed)
│   ├── services/
│   │   ├── api_client.dart        # cliente HTTP (Dio → FastAPI)
│   │   ├── backend_launcher.dart  # inicia o backend Python em background
│   │   └── system_info_service.dart
│   └── theme/
│       ├── app_colors.dart
│       ├── app_text_styles.dart
│       ├── app_spacing.dart
│       └── app_theme.dart
├── features/
│   ├── dashboard/                 # métricas e KPIs dos modelos
│   ├── models/                    # listagem e gestão de modelos salvos
│   ├── monitoring/                # status do sistema e do backend
│   ├── projects/                  # CRUD de projetos (SQLite)
│   ├── results/                   # tela de loading e dashboard pós-treino
│   └── workspace/                 # configuração de dataset + treinamento
├── shared/
│   ├── providers/                 # providers Riverpod globais
│   └── widgets/                   # componentes reutilizáveis
└── main.dart                      # entrypoint (SQLite init + window setup)
```

---

## Tecnologias

| Biblioteca | Uso |
|-----------|-----|
| [Flutter](https://flutter.dev/) | Framework UI multiplataforma |
| [Riverpod](https://riverpod.dev/) | Gerenciamento de estado reativo |
| [Dio](https://pub.dev/packages/dio) | Cliente HTTP para o backend |
| [sqflite_ffi](https://pub.dev/packages/sqflite_common_ffi) | SQLite local para projetos (Windows) |
| [window_manager](https://pub.dev/packages/window_manager) | Controle da janela desktop |
| [fl_chart](https://pub.dev/packages/fl_chart) | Gráficos de performance |
| [file_picker](https://pub.dev/packages/file_picker) | Seleção de arquivos CSV |
| [Freezed](https://pub.dev/packages/freezed) | Modelos de dados imutáveis |
| [google_fonts](https://pub.dev/packages/google_fonts) | Tipografia |

---

## Problemas comuns

| Erro | Causa | Solução |
|------|-------|---------|
| Backend offline (status vermelho) | FastAPI não está rodando | Execute `uvicorn main:app --reload` no repositório do backend |
| `flutter doctor` reporta Visual Studio | Workload C++ ausente | Instale "Desktop development with C++" no Visual Studio Installer |
| `MissingPluginException` | `flutter pub get` não foi executado | Rode `flutter pub get` e reinicie |
| Tela em branco ao abrir | Resolução abaixo do mínimo | A janela exige pelo menos 1024 × 700 px |
| `build_runner` falha | Arquivos gerados desatualizados | Rode `dart run build_runner build --delete-conflicting-outputs` |

---

## Projeto

Desenvolvido para o NOVAML — trabalho da disciplina de Engenharia de Software, UFC — Departamento de Computação.

**Equipe:**
- Davi Teixeira Silva — Quality Assurance
- Jander Nunes Soares — Gerente de Projeto
- Lazuli Costa de Andrade — Desenvolvedor Back-End
- Leonardo Quezado de Meneses — IA Engineer
- Maurycio Kemesson Nascimento Brito — Desenvolvedor Front-End
- Nathalia Moura Cardoso — Desenvolvedor Front-End
