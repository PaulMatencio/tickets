// Load the mongodb data base
import 'dart:io';
import 'dart:async';
// import 'dart:convert';
import 'db_config.dart';
import 'package:resource/resource.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:json_object/json_object.dart';

main() async {
  DbConfigValues config = new DbConfigValues();
  var importer = new Seeder(config.dbName, config.dbURI, config.dbSeed);

  // print("${await importer.readFile()}"); OK
  // importer.filetoJsonPrint();
  importer.readJsonFile();
}

class Seeder {
  final String _dbURI;
  final String _dbName;
  final Resource _dbSeedFile;

  Seeder(String this._dbName, String this._dbURI, Resource this._dbSeedFile);

  Future readJsonFile() {
    return _dbSeedFile
        .readAsString() // Read an Item asynchrously
        .then((String item) => new JsonObject.fromJsonString(
            item)) //  convert it  to a Json object
        .then(printJson) //  print the Json object
        .then(insertJsonToMongo) // insert the Json object into MongoDB
        .then(closeDatabase); // close the mongoDb database
  }

  /* readFile() and filetoJsonprint are not used */
  readFile() async => await (_dbSeedFile.readAsString()); // OK
  filetoJsonPrint() async =>
      printJson(await (new JsonObject.fromJsonString((await _dbSeedFile
          .readAsString())))); //OK to replace the Future readJsonFile()

  //  print a Json object
  JsonObject printJson(JsonObject json) {
    json.keys.forEach((String collectionKey) {
      // use the keys collection to acquire the list of map items
      print('Collections Name:' + collectionKey);
      var collection = json[collectionKey];
      print('Collection:' + collection.toString());
      collection.forEach((document) {
        print('Document:' + document.toString());
      });
    });
    return json; // to a jsonObject to  next .then
  }

  Future insertJsonToMongo(JsonObject json) async {
    // Create a Mongo DB instance
    Db database = new Db(_dbURI + _dbName);
    // Asynchrnously open the database
    await database.open();
    // Insert collection
    await Future.forEach(json.keys, (String collectionName) async {
      // use the keys collection to acuire the list of map items
      DbCollection collection = new DbCollection(database, collectionName);
      // save all the entities of one collection in one call
      return collection.insertAll(json[collectionName]);
    });
    return database; // to the next .then
  }

  Future closeDatabase(Db database) {
    return database.close();
  }
}
