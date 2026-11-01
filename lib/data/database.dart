import 'dart:io';

import 'package:postgres/postgres.dart';

class DatabaseConfig {
  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });

  factory DatabaseConfig.fromEnvironment() {
    const host = String.fromEnvironment('DB_HOST');
    return DatabaseConfig(
      host: host.isNotEmpty ? host : _defaultHost(),
      port: const int.fromEnvironment('DB_PORT', defaultValue: 5435),
      database: const String.fromEnvironment(
        'DB_NAME',
        defaultValue: 'tagihan_air',
      ),
      username: const String.fromEnvironment(
        'DB_USER',
        defaultValue: 'tagihan',
      ),
      password: const String.fromEnvironment(
        'DB_PASSWORD',
        defaultValue: 'tagihan',
      ),
    );
  }

  static String _defaultHost() => Platform.isAndroid ? '10.0.2.2' : 'localhost';

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

  Endpoint get endpoint => Endpoint(
    host: host,
    port: port,
    database: database,
    username: username,
    password: password,
  );

  @override
  String toString() => '$host:$port/$database';
}

Pool<void> openPool(DatabaseConfig config) {
  return Pool.withEndpoints(
    [config.endpoint],
    settings: const PoolSettings(
      maxConnectionCount: 2,
      connectTimeout: Duration(seconds: 5),
      sslMode: SslMode.disable,
    ),
  );
}
