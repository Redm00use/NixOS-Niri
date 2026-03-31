# NixOS Installer

Основная точка входа:

```bash
python3 ./scripts/install.py
```

По умолчанию это встроенный пошаговый TUI без внешних зависимостей.

Структура Python installer:
- `scripts/installer/cli.py` — основной сценарий
- `scripts/installer/prompts.py` — интерактивные вопросы и валидация
- `scripts/installer/disk.py` — разметка, форматирование, mount, install
- `scripts/installer/meta.py` — генерация `hosts/<host>/meta.nix`
- `scripts/installer/common.py` — общие пути и shell helpers

Это сделано, чтобы installer было проще поддерживать и расширять.
