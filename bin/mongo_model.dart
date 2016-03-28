library ticket_models;

import 'dart:async';
import 'dart:mirrors';
import 'package:mongo_dart/mongo_dart.dart';
import 'mongo_pool.dart';
import 'package:tickets/shared/schemas.dart';
import 'package:connection_pool/connection_pool.dart';

class MongoModel {
  // CONNECT TO MONGODB
  MongoDbPool _dbPool;
  MongoModel(String _databaseName, String _databaseUrl, int _databasePoolSize) {
    _dbPool = new MongoDbPool(_databaseUrl + _databaseName, _databasePoolSize);
  }

  dynamic mapToDto(cleanObject, Map document) {
    var reflection = reflect(cleanObject);

    // document['id'] = document['_id'].toString();
    document['id'] = document['_id'].toJson();

    document.remove('_id');
    document.forEach((k, v) {
      reflection.setField(new Symbol(k), v);
    });
    return cleanObject;
  }

  Map dtoToMap(Object object) {
    var reflection = reflect(object);
    Map target = new Map();
    var type = reflection.type;
    while (type != null) {
      type.declarations.values.forEach((item) {
        if (item is VariableMirror) {
          VariableMirror value = item;
          if (!value.isFinal) {
            target[MirrorSystem.getName(value.simpleName)] =
                reflection.getField(value.simpleName).reflectee;
          }
        }
      });
      type = type.superclass;
      //get properties from superclass too!
    }
    return target;
  }

  Map dtoToMongoMap(object) {
    Map item = dtoToMap(object);
    // mongo uses an underscore prefix which would act as a private field in dart
    // convert only on write to mongo

    //item['_id'] = item['id'];
    item['_id'] = new ObjectId.fromHexString(item['id']);

    item.remove('id');
    item.remove('collection_key');
    return item;
  }

  dynamic getInstance(Type t) {
    MirrorSystem mirrors = currentMirrorSystem();
    LibraryMirror lm = mirrors.libraries.values.firstWhere(
        (LibraryMirror lm) => lm.qualifiedName == new Symbol('ticket_schemas'));
    ClassMirror cm = lm.declarations[new Symbol(t.toString())];
    InstanceMirror im = cm.newInstance(new Symbol(''), []);
    return im.reflectee;
  }

  // 10.9
  Future<BaseDTO> createByItem(BaseDTO item) {
    assert(item.id == null);

    // item.id = new ObjectId().toString();
    item.id = new ObjectId().toJson();
    print(item.id);

    return _dbPool.getConnection().then((ManagedConnection mc) {
      Db db = mc.conn;
      DbCollection collection = db.collection(item.collection_key);

      Map aMap = dtoToMongoMap(item);

      return collection.insert(aMap).then((status) {
        _dbPool.releaseConnection(mc);
        return (status['ok'] == 1) ? item : null;
      });
    });
  }

  //10.10
  Future<Map> deleteByItem(BaseDTO item) async {
    assert(item.id != null);
    return _dbPool.getConnection().then((ManagedConnection mc) {

      Db database = mc.conn;
      DbCollection collection = database.collection(item.collection_key);

      Map aMap = dtoToMongoMap(item);

      return collection.remove(aMap).then((status) {
        _dbPool.releaseConnection(mc);
        return status;
      });
    });
  }

  //10.11
  Future<Map> updateItem(BaseDTO item) async {
    assert(item.id != null);
    return _dbPool.getConnection().then((ManagedConnection mc) async {
      Db database = mc.conn;
      DbCollection collection = new DbCollection(database, item.collection_key);

      // Map selector = {'_id':item.id};
      Map selector = {'_id': new ObjectId.fromHexString(item.id)};

      Map newItem = dtoToMongoMap(item);
      return collection.update(selector, newItem).then((status) {
        _dbPool.releaseConnection(mc);
        return status;
      });
    });
  }

  //10.12
  Future<List> _getCollection(String collectionName, [Map query = null]) {
    return _dbPool.getConnection().then((ManagedConnection mc) async {
      DbCollection collection = new DbCollection(mc.conn, collectionName);
      return collection.find(query).toList().then((List<Map> maps) {
        _dbPool.releaseConnection(mc);
        return maps;
      });
    });
  }

  //10.13
  Future<List> _getCollectionWhere(String collectionName, fieldName, values) {
    return _dbPool.getConnection().then((ManagedConnection mc) async {
      Db database = mc.conn;
      DbCollection collection = new DbCollection(database, collectionName);
      SelectorBuilder builder = where.oneFrom(fieldName, values);
      return collection.find(builder).toList().then((map) {
        _dbPool.releaseConnection(mc);
        return map;
      });
    });
  }

  //10.14
  //refresh an item from the database instance
  Future<BaseDTO> readItemByItem(BaseDTO matcher) async {
    assert(matcher.id != null);

    // Map query = {'_id': matcher.id};
    Map query = {'_id': new ObjectId.fromHexString(matcher.id)};

    BaseDTO bDto;
    return _getCollection(matcher.collection_key, query).then((items) {
      bDto = mapToDto(getInstance(matcher.runtimeType), items.first);
      return bDto;
    });
  }

  //acquires a collection of documents based off a type, and field values
  Future<List> readCollectionByTypeWhere(t, fieldName, values) async {
    List list = new List();
    BaseDTO freshInstance = getInstance(t);
    return _getCollectionWhere(freshInstance.collection_key, fieldName, values)
        .then((items) {
      items.forEach((item) {
        list.add(mapToDto(getInstance(t), item));
      });
      return list;
    });
  }

  //acquires a collection of documents based off a type and an optional query
  Future<List> readCollectionByType(t, [Map query = null]) async {
    List list = new List();
    BaseDTO freshInstance = getInstance(t);
    return _getCollection(freshInstance.collection_key, query).then((items) {
      items.forEach((item) {
        list.add(mapToDto(getInstance(t), item));
      });
      return list;
    });
  }

  // DROP A DATABASE
  Future<Map> dropDatabase() async {
    var connection = await _dbPool.getConnection();
    var database = connection.conn;
    Map status = await database.drop();
    return status;
  }
}
