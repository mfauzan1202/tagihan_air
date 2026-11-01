# Tagihan Air

A small Flutter app for keeping track of monthly water bills: who owes what, for
which period, and when it is due. Bills live in a local Postgres database that
runs in Docker.

- Bill list sorted by due date, with a Belum bayar / Lunas / Semua filter and
  due labels such as "3 hari lagi" or "Terlambat 2 hari".
- Add and edit form with validation, a due date picker and Rupiah formatting.
- Detail screen with Tandai lunas, Edit and Hapus (with confirmation).
- Every bill has its own route, `/bills/:id`, so a bill can be opened from its
  id alone.
- About ten sample bills are inserted on first launch, dated relative to the
  day the app first runs.

## Requirements

- Flutter 3.44 (Dart 3.12)
- Docker
- Xcode with an iOS Simulator, or an Android emulator

## Running

Start Postgres, then run the app:

```sh
docker compose up -d
flutter run
```

The app connects to `localhost:5435`, database `tagihan_air`, user and password
`tagihan`. Port 5435 is used so it does not clash with a Postgres already
running on 5432. To change the host port, set `DB_PORT` for both:

```sh
DB_PORT=5440 docker compose up -d
flutter run --dart-define=DB_PORT=5440
```

`DB_HOST`, `DB_NAME`, `DB_USER` and `DB_PASSWORD` can be overridden the same
way. The iOS Simulator shares the Mac's network, so `localhost` works there. On
the Android emulator the app uses `10.0.2.2` by default, which points to the
host machine.

The schema is created by the app on startup (`lib/data/migrations.dart`). To
start over with fresh sample data:

```sh
docker compose down -v
docker compose up -d
```

## Tests

```sh
flutter test
```

The repository tests in `test/data/postgres_bill_repository_test.dart` run
against the `tagihan_air_test` database created by the Docker init script, so
Postgres has to be up. To run everything else without a database:

```sh
flutter test --exclude-tags postgres
```

## Project structure

```
lib/
  main.dart              entry point, sets up ProviderScope and id_ID dates
  app.dart               MaterialApp, theme and locale
  router.dart            go_router routes
  models/                Bill and BillDraft
  data/                  Postgres connection, migrations, repository, seed data
  state/                 Riverpod providers
  ui/
    formatting.dart      Rupiah, dates, due labels, thousands input formatter
    screens/             list, form, detail, settings
    widgets/             tile, due badge, filter bar, dialogs
test/
  data/                  repository (Postgres) and seed tests
  models/                Bill tests
  state/                 provider tests
  ui/                    widget tests
  support/               in-memory repository and fixtures
docker/initdb/           creates the test database on first start
```

Screens never talk to the database directly. They read and change bills
through the providers in `lib/state/`, which call `BillRepository`.
`PostgresBillRepository` is the only implementation the app uses. Widget tests
swap in an in-memory one.

## License

[CC0 1.0 Universal](LICENSE). The repository has no third-party assets. The
launcher icon was drawn for this project, and the Material icons used in the UI
come from the Flutter SDK at build time.
