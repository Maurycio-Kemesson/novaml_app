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
cd novaml_ap