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
└── data/                   ← Criada em runtime: database.db + modelos .pkl
```

## Como rodar

1. Copie a pasta `release/` inteira para onde quiser (ex: `C:\NOVAML\`).
2. Execute `novaml_app.exe`.
3. O app detecta o `novaml_api.exe` na mesma pasta e o inicia automaticamente
   como processo filho — **não é necessário ter Python instalado**.

> Não mova ou apague nenhum `.dll`/`.exe` individualmente: eles precisam
> permanecer juntos na mesma pasta para o app funcionar.

## Atualizando o executável desta pasta

Sempre que houver uma nova versão:

**Frontend mudou:**
```cmd
cd novaml_app
flutter build windows --release
copy /Y build\windows\x64\runner\Release\novaml_app.exe release\
xcopy /y build\windows\x64\runner\Release\*.dll release\
```

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
