# NOVAML App — Interface Desktop No-Code para Machine Learning Astronômico

Frontend desktop da plataforma NOVAML, construído com Flutter para Windows. Permite criar projetos, configurar datasets CSV astronômicos, selecionar algoritmos e treinar modelos de Machine Learning sem escrever código, comunicando-se com o backend FastAPI via HTTP local.

---

## Instalação do Executável (Usuário Final)

Esta é a forma mais simples de rodar o NOVAML — **não é necessário instalar Flutter, Dart, Python ou qualquer ferramenta de desenvolvimento**. O executável já embute o frontend e o backend prontos para uso.

### Requisitos mínimos do computador

| Item | Mínimo | Recomendado |
|---|---|---|
| Sistema operacional | Windows 10 64-bit (versão 1809+) | **Windows 11 64-bit** |
| Arquitetura | x64 | x64 |
| Processador | Dual-core 2 GHz | Quad-core 2.5 GHz+ |
| Memória RAM | 4 GB | 8 GB+ |
| Espaço em disco | 500 MB livres | 1 GB+ (datasets e modelos treinados aumentam o uso) |
| Resolução de tela | 1024 × 700 | 1366 × 768 ou superior |
| Permissões | Usuário padrão (sem admin) | — |
| Rede | Não requer internet — tudo roda em `localhost` | — |

> O NOVAML é desenvolvido e testado prioritariamente em **Windows 11**. Windows 10 64-bit é suportado como piso mínimo, mas pode exigir a atualização de componentes do sistema (Visual C++ Redistributable 2015-2022, normalmente já presente no Windows 11).

### Passo a passo

1. **Obtenha a pasta `release/`** deste repositório (`novaml_app/release/`) — ela contém `novaml_app.exe`, `novaml_api.exe` e todas as DLLs necessárias já centralizados juntos.
2. **Copie a pasta inteira** para um local de sua preferência no computador (ex: `C:\NOVAML\`). Não é necessário instalar nada.
3. **Não separe os arquivos**: `novaml_app.exe`, `novaml_api.exe` e as `.dll` precisam permanecer na mesma pasta — o frontend inicia o backend automaticamente como processo filho.
4. **Execute `novaml_app.exe`** com duplo clique.
5. Aguarde a inicialização automática do backend (leva alguns segundos). Você pode acompanhar o status na tela **Monitoramento**: o indicador fica verde quando o backend está pronto.
6. Se o Windows SmartScreen exibir um aviso ("Windows protegeu o computador"), clique em **Mais informações → Executar assim mesmo** — isso ocorre porque o executável ainda não possui assinatura digital (comum em builds internos/PyInstaller).
7. Pronto — crie um projeto e comece a treinar modelos. Nenhum dado é enviado para a internet; tudo roda localmente.

> Detalhes sobre o conteúdo da pasta `release/` e como atualizá-la a cada nova versão estão em [`release/README.md`](release/README.md).

---

## Pré-requisitos (Desenvolvimento)

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) 3.22+
- Dart SDK 3.3+
- Visual Studio 2022 com workload **Desktop development with C++**
- Git
- Backend NOVAML rodando em `http://localhost:8000`

> Para verificar: `flutter doctor` — todos os itens relevantes para Windows devem estar marcados com ✓.

---

## Instalação (Desenvolvimento)

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
│ 