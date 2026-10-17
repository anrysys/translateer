# Разработка Translateer

## Как устроено

Translateer — один bash-скрипт [`translateer`](translateer) поверх готовых утилит:

| Утилита | Пакет | Зачем |
|---|---|---|
| `wl-paste` | wl-clipboard | читает выделенный текст (primary selection) или буфер обмена |
| `trans` | translate-shell | переводит |
| `zenity` | zenity | окна: выбор направления, результат, ввод текста |
| `notify-send` | libnotify-bin | уведомление, когда нечего переводить |
| `gsettings` | (есть в GNOME) | назначает горячую клавишу |

Режимы запуска:

- `translateer` — перевод выделенного текста. Так программу вызывает горячая клавиша.
- `translateer --input` — окно для ввода текста. Так программа запускается из меню (`Exec` в `.desktop`-файле); при первом запуске в этом режиме вызывается `setup_hotkey`.

### Горячая клавиша

Пакет сам клавишу не назначает: скрипты установки `.deb` работают от root и не видят настроек пользователя. Поэтому её назначает функция `setup_hotkey` — один раз для каждого пользователя (флаг `~/.config/translateer/hotkey-configured`):

1. Если в системе нет схемы `org.gnome.settings-daemon.plugins.media-keys` (не GNOME) — показывает инструкцию для ручной настройки.
2. Ищет `<Control><Alt>e` во всех схемах (`gsettings list-recursively`) и в пользовательских настройках (`dconf dump /`). Если сочетание занято — показывает инструкцию.
3. Иначе добавляет особую комбинацию по пути `/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/translateer/`.

### Направление перевода

Язык текста угадывается по буквам: `і ї є ґ` → украинский, другая кириллица → русский, иначе английский. Если в прошлый раз переводили с того же языка, в меню отмечается то же направление (`~/.config/translateer/last-direction`), иначе — ru→en, en→ru или uk→ru.

## Структура

```
translateer                                      скрипт программы → /usr/bin/translateer
data/translateer.svg                             иконка; из неё при сборке делаются PNG 16–256 px
data/translateer.desktop                         ярлык в меню приложений
data/io.github.anrysys.Translateer.metainfo.xml  карточка AppStream для App Center и других магазинов
changelog                                        журнал изменений в формате Debian
build-deb.sh                                     сборка .deb
```

## Сборка

Нужны `dpkg-deb` (есть в любой Ubuntu/Debian), `rsvg-convert` (пакет `librsvg2-bin`) и `gzip`.

```bash
./build-deb.sh
```

Пакет появится в `dist/translateer_<версия>_all.deb`, дерево файлов пакета — в `build/`.

## Проверка

```bash
bash -n translateer                                                   # синтаксис
./translateer                                                         # запуск без установки
desktop-file-validate data/translateer.desktop                        # пакет desktop-file-utils
appstreamcli validate data/io.github.anrysys.Translateer.metainfo.xml # пакет appstream
appstreamcli validate-tree build/translateer_*_all                    # после сборки: .desktop + иконки + metainfo
apt-get install -s ./dist/translateer_*_all.deb                       # зависимости, без установки
```

Без установки горячая клавиша работать не будет: она вызывает команду `translateer` из `PATH`. Чтобы проверить первый запуск «с нуля», удалите `~/.config/translateer/` и особую комбинацию Translateer в настройках клавиатуры.

## Выпуск новой версии

1. Поднимите `version` в `build-deb.sh`.
2. Добавьте запись в начало `changelog` (формат Debian: `dch` из пакета `devscripts` или вручную).
3. Добавьте `<release>` в `data/io.github.anrysys.Translateer.metainfo.xml`.
4. Соберите пакет и опубликуйте релиз:

   ```bash
   ./build-deb.sh
   git commit -am "Translateer 1.1.0" && git tag v1.1.0 && git push --follow-tags
   gh release create v1.1.0 dist/translateer_1.1.0_all.deb --title "Translateer 1.1.0" --notes "Что изменилось"
   ```
