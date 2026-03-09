import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart' as native;

Future<CommonDatabase> openAppDatabase(String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, fileName);
  return native.sqlite3.open(path);
}
