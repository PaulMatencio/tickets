import 'package:guinness/guinness.dart'; //test framework
import 'package:tickets/shared/schemas.dart'; //test dtos
import 'package:tickets/db/seeder.dart'; //json file
import 'package:tickets/db/db_config.dart'; //database values
import '../bin/mongo_model.dart';

main() {
  DbConfigValues config = new DbConfigValues();
  MongoModel model =
      new MongoModel(config.testDbName, config.testDbURI, config.testDbSize);
  //A Test DTO
  RouteDTO routeDTO = new RouteDTO();
  routeDTO.route = "SFO-NYC";
  routeDTO.duration = 120;
  routeDTO.price1 = 90.00;
  routeDTO.price2 = 91.00;
  routeDTO.price3 = 95.00;
  routeDTO.seats = 7;

  describe("The Ticket MongoModel", () {
    it('Should populate the Test Database', () async {
      Seeder seeder =
          new Seeder(config.testDbName, config.testDbURI, config.testDbSeed);
      await seeder.readJsonFile(); // seeder.dart
      List collection = await model.readCollectionByType(RouteDTO);
      expect(collection.length).toBeGreaterThan(10);
    });

    it("should create a route DTO and write to the db", () {
      var originalID = routeDTO.id;
      return model.createByItem(routeDTO).then((var dto) {
        expect(originalID).toBeNull();
        expect(routeDTO.id).toBeNotNull();
        expect(dto.id).toEqual(routeDTO.id);
      });
    });

    var action =
        "update previous db item, retrieve it to make sure its updated";
    it(action, () {
      routeDTO.price1 = 10000.10;
      return model.updateItem(routeDTO).then((status) {
        return model.readItemByItem(routeDTO).then((dto) {
          expect(status['ok']).toEqual(1.0);
          expect(dto.price1).toEqual(routeDTO.price1);
        });
      });
    });

    it("should retrieve a list of items by the DTO", () {
      return model.readCollectionByType(RouteDTO).then((List<BaseDTO> aList) {
        expect(aList.first).toBeAnInstanceOf(RouteDTO);
        expect(aList.length).toBeGreaterThan(10);
      });
    });


    it("will retrieve the item created in the first step", () {
      return model.readItemByItem(routeDTO).then((BaseDTO dto) {
        expect(dto.id).toEqual(routeDTO.id);
      });
    });

    it("should delete the route DTO from the DB", () {
      return model.deleteByItem(routeDTO).then((status) {
        expect(status['ok']).toEqual(1.0);
      });
    });

    /*
    it("should drop a collection", () async {
      bool status = await model.dropCollection("Routes");
      expect(status).toBeTrue();
    });
    */


    it("should drop the test database", () async {
      Map status = await model.dropDatabase();
      expect(status['ok']).toEqual(1.0);
    });

  });
}
