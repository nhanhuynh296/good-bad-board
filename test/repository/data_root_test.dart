import 'package:good_bad_board/repository/data_root.dart';
import 'package:test/test.dart';

void main() {
  test('should_refuse_production_data_root_under_flutter_test', () {
    expect(DataRoot.production().resolve(), throwsStateError);
  });

  test('should_resolve_given_directory', () async {
    expect(await DataRoot.directory('/sandbox').resolve(), '/sandbox');
  });
}
