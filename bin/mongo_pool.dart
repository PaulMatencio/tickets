import 'package:mongo_dart/mongo_dart.dart';
import 'dart:async';
import 'package:connection_pool/connection_pool.dart';

// ConnectionPool<T> accepts a generic Type T
class MongoDbPool extends ConnectionPool<Db> {
  // expect mongo_dart class of Db
  String uri;

  // Constructor method of the MomgDbPool Class
  MongoDbPool(String this.uri, int poolSize) : super(poolSize);

  //overrides method in ConnectionPool
  void closeConnection(Db conn) {
    conn.close();
  }

  //overrides method in ConnectionPool
  Future<Db> openNewConnection() {
    var conn = new Db(uri);
    return conn.open().then((_) => conn);
  }
}
