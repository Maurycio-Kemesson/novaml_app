# NOVAML — Pasta de Release (Executável Centralizado)

Esta pasta reúne o **executável final e pronto para uso** do NOVAML: o frontend
Flutter (`novaml_app.exe`) e o backend Python empacotado (`novaml_api.exe`),
lado a lado — exatamente como é necessário para rodar a aplicação sem precisar
compilar nada.

```
release/
├── novaml_app.exe          ← Frontend (Flutter Windows Release build)
├── novaml_api.exe          ← Backend (PyInstaller — embute Python + libs)
├── flutter_windows.dll     ← Runtime Flutter (obrigatório)
├── dartjni.dll
├── desktop_drop_plugin.dll
├── screen_retriever_plugin.dll
├── sqlite3.dll
├── window_manager_plugin.dll
└── data/
    ├── flutter_assets/     ← OBRIGATÓRIO — assets do Flutter (fontes, ícones, imagens)
    ├── icudtl.dat          ← OBRIGATÓRIO — dados ICU exigidos pelo motor Flutter
    ├── app.so              ← OBRIGATÓRIO — snapshot AOT do código Dart
    ├── database.db         ← Criado em runtime pelo backend (modelos treinados)
    └── models/             ← Criado em runtime pelo backend (arquivos .pkl exportados)
```

> **Atenção:** `flutter_assets/`, `icudtl.dat` e `app.so` vêm do próprio build
> do Flutter (`build\windows\x64\runner\Release\data\`) e são **obrigatórios**
> para o motor do Flutter inicializar. Sem eles, `novaml_app.exe` falha
> silenciosamente ao abrir — nenhuma janela, nenhum erro, nenhum processo
> visível no Gerenciador de Tarefas. O backend usa a **mesma** pasta `data/`
> para gravar `database.db` e `models/` em runtime — os dois convivem juntos
> sem conflito.

## Como rodar

1. Copie a pasta `release/` inteira para onde quiser (ex: `C:\NOVAML\`).
2. Execute `novaml_app.exe`.
3. O app detecta o `novaml_api.exe` na mesma pasta e o inicia automaticamente
   como processo filho — **não é necessário ter Python instalado**.

> Não mova ou apague nenhum `.dll`/`.exe`/arquivo de `data/` individualmente:
> eles precisam permanecer juntos na mesma pasta para o app funcionar.

## Atualizando o executável desta pasta

Sempre que houver uma nova versão:

**Frontend mudou:**
```cmd
cd novaml_app
flutter build windows --release
copy /Y build\windows\x64\runner\Release\novaml_app.exe release\
xcopy /y build\windows\x64\runner\Release\*.dll release\
xcopy /s /e /y build\windows\x64\runner\Release\data\flutter_assets release\data\flutter_assets\
copy /Y build\windows\x64\runner\Release\data\icudtl.dat release\data\
copy /Y build\windows\x64\runner\Release\data\app.so release\data\
```

> Não esqueça do `data\flutter_assets`, `icudtl.dat` e `app.so` — sem eles o
> app não abre (ver aviso acima).

**Backend mudou** (pegue sempre o `.exe` mais recente gerado no repositório
`novaml-api`):
```cmd
cd ..\novaml-api
build_backend.bat
copy /Y dist\novaml_api.exe ..\novaml_app\release\novaml_api.exe
```

## Versionamento no Git (LFS)

Os arquivos `.exe`/`.dll` desta pasta são versionados via **Git LFS**
(configurado em `.gitattributes` na raiz do `novaml_app`), para não inflar o
histórico do repositório a cada novo build. Antes do primeiro commit destes
binários em uma máquina nova:

```cmd
git lfs install
git add .gitattributes release/
git commit -m "release: atualiza executável"
git push
```

Sem o `git lfs install`, o Git tentará versionar os binários normalmente —
rode o comando acima uma vez por máquina/clone.

### Clonando em outra máquina (novo colaborador)

Depois de clonar o repositório, rode `git lfs install` uma vez (se ainda não
tiver — instaladores recentes do Git para Windows já vêm com o Git LFS
incluso) e depois `git lfs pull` caso os `.exe`/`.dll` da pasta `release/`
apareçam com poucos KB em vez do tamanho real. Isso acontece quando o `git
clone`/`git pull` foi feito sem o Git LFS ativo: em vez do binário completo,
você recebe apenas o **arquivo-ponteiro** (um texto pequeno com o hash e o
tamanho do arquivo original), que não é um executável válido.

```powershell
git lfs install
git lfs pull
```

> Cada `clone`/`pull` completo desses binários conta na cota de banda do Git
> LFS do GitHub (1 GB/mês no plano gratuito) — não é necessário rodar
> `git lfs pull` repetidamente sem necessidade.
