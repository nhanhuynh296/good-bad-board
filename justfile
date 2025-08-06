default:
    just --choose

generate:
    flutter pub get
    flutter gen-l10n
    dart run build_runner build --delete-conflicting-outputs --verbose --track-performance

lint:
    flutter analyze --fatal-infos --no-pub
    dart format --output=none --set-exit-if-changed .
