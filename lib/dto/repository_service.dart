import 'dart:io';

import 'package:path_provider/path_provider.dart';

class RepositoryService {
  RepositoryService._();

  static final RepositoryService instance = RepositoryService._();

  late final Directory appDir;

  Future<void> initialize() async {
    appDir = await getApplicationDocumentsDirectory();
  }

  String get rootPath => appDir.path;
}
