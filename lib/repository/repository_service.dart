import 'dart:developer';

import 'package:good_bad_board/repository/database_helper.dart';
import 'package:path_provider/path_provider.dart';

class RepositoryService {
  RepositoryService._();

  static final RepositoryService instance = RepositoryService._();

  late final String rootPath;

  Future<void> initialize() async {
    rootPath = (await getApplicationDocumentsDirectory()).path;
    log('Application root path: $rootPath');
    await DatabaseHelper.instance.initialize();
  }
}
