import 'package:resource/resource.dart';

class DbConfigValues {
  String dbName = 'Tickets';
  String dbURI = 'mongodb://127.0.0.1:27017/';

  /* A resource is data that can be located using a URI and read into
  * the program at runtime.
  * The URI may use the `package` scheme to read resources provided
  * along with package sources.
  */

  Resource dbSeed = const Resource('package:tickets/db/seed.json');

  int dbSize = 10;

  String get testDbName => dbName + "-test";

  String get testDbURI => dbURI;

  Resource get testDbSeed => dbSeed;

  int get testDbSize => dbSize;
}
