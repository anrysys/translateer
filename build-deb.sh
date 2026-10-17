#!/bin/bash
# Собирает пакет dist/translateer_<версия>_all.deb
set -euo pipefail
cd "$(dirname "$0")"

version=1.0.0
root=build/translateer_${version}_all
share=$root/usr/share

rm -rf "$root"
install -Dm755 translateer "$root/usr/bin/translateer"
install -Dm644 data/translateer.desktop "$share/applications/translateer.desktop"
install -Dm644 data/io.github.anrysys.Translateer.metainfo.xml "$share/metainfo/io.github.anrysys.Translateer.metainfo.xml"
install -Dm644 data/translateer.svg "$share/icons/hicolor/scalable/apps/translateer.svg"
for size in 16 24 32 48 64 128 256; do
    mkdir -p "$share/icons/hicolor/${size}x${size}/apps"
    rsvg-convert -w $size -h $size data/translateer.svg -o "$share/icons/hicolor/${size}x${size}/apps/translateer.png"
done
install -Dm644 LICENSE "$share/doc/translateer/copyright"
gzip -9n < changelog > "$share/doc/translateer/changelog.gz"
chmod -R u=rwX,go=rX "$root"

installed_size=$(du -sk "$root" | cut -f1)
mkdir -p "$root/DEBIAN"
cat > "$root/DEBIAN/control" <<CONTROL
Package: translateer
Version: $version
Architecture: all
Maintainer: andriiakishyn <andriiakishyn@gmail.com>
Installed-Size: $installed_size
Depends: translate-shell, wl-clipboard, zenity, libnotify-bin
Section: utils
Homepage: https://github.com/anrysys/translateer
Priority: optional
Description: translate selected text between English, Russian and Ukrainian
 Select text in any application and press Ctrl+Alt+E to see its translation.
 Six directions between English, Russian and Ukrainian are available, and the
 result can be translated back with one button to check it. Launch it from the
 app menu to type text by hand.
 .
 The shortcut is assigned in GNOME on first launch from the app menu, if
 Ctrl+Alt+E is free. Translation uses translate-shell and needs an internet
 connection.
CONTROL

mkdir -p dist
dpkg-deb --root-owner-group -Zxz --build "$root" dist/
