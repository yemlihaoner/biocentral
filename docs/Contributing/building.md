# Building

Overview how to build biocentral for different platforms locally.

## Python Companion

Build python companion via `serious_python` package command before building the flutter app:

```shell
# Windows
dart run serious_python:main package --asset assets/python_companion.zip python_companion/ -p Windows --requirements "-r,python_companion/requirements.txt"
# Linux
dart run serious_python:main package --asset assets/python_companion.zip python_companion/ -p Linux --requirements "-r,python_companion/requirements.txt"
# macOS
dart run serious_python:main package --asset assets/python_companion.zip python_companion/ -p Darwin --requirements "-r,python_companion/requirements.txt"
# Web
dart run serious_python:main package --asset assets/python_companion.zip python_companion/ -p Pyodide --requirements "-r,python_companion/requirements.txt"
unzip assets/python_companion.zip -d assets/python_companion
```

## Linux

```shell
# Create release build
flutter build linux --release
```

### AppImage

```shell
# Download AppImageKit: https://github.com/AppImage/AppImageKit/releases
# Change file mode
chmod +x appimagetool-x86_64.AppImage

# Copy release to AppDir directory
cp -r build/linux/x64/release/bundle/ releases/current/biocentral.AppDir

# Create AppRun file
#!/bin/sh
cd "$(dirname "$0")"
exec ./biocentral

# Change file mode
chmod +x AppRun

# Create .desktop file https://wiki.ubuntuusers.de/.desktop-Dateien/
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name=Biocentral
Comment=Biomedical data, from lab to paper.
Exec=biocentral %u
Icon=biocentral_logo
Categories=Science;

# Copy logo to dir
cp assets/biocentral_logo/biocentral_logo.png releases/current/biocentral.AppDir/

# Bundling to AppImage
./appimagetool-x86_64.AppImage biocentral.AppDir/ biocentral_vX.X.X.AppImage
```

## Web

```shell
# Building for biocentral.cloud, omit --base-href if building for local deployment
flutter build web --base-href /app/
```

## Windows

```shell
# Create release build (.exe)
flutter build windows --release
```