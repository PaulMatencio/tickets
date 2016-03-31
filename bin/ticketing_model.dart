import 'dart:async';
import 'mongo_model.dart'; // mongodb model
import 'package:tickets/shared/schemas.dart'; // mongoDB schema
import 'package:tickets/db/db_config.dart'; // mongoDB Config
import 'package:dartson/dartson.dart';

class TicketingModel {
  MongoModel _mongo;

  TicketingModel() {
    DbConfigValues config = new DbConfigValues();
    _mongo = new MongoModel(config.dbName, config.dbURI, config.dbSize);
  }

  // Future methoName(Map params) {
  // return _mongo.action(DTO)
  // }
  Future getAllCities(Map params) {
    print(params);
    return _mongo.readCollectionByType(CityDTO);
  }

  Future getAllTimes(Map params) {
    return _mongo.readCollectionByType(TimeDTO);
  }

  // expect a Map as parameter
  Future createPurchase(Map params) async {
    // instantiate an instance of  Dartson
    var dson = new Dartson.JSON();
    PurchaseDTO purchaseDTO = dson.map(params, new PurchaseDTO());
    //
    TransactionDTO tDTO = new TransactionDTO();
    tDTO.paid = 1000; // we are faking a sucessful credit card payment
    tDTO.user = purchaseDTO.pEmail;
    // record  a transaction item to transaction collection
    await _mongo.createByItem(tDTO);
    purchaseDTO.transactionId = tDTO.id;
    // record  a purchase item to the purchase collection
    return _mongo.createByItem(purchaseDTO);
  }

  // Get arrival and departure times per City
  // Nested DTO
  // The timeDTO contain a corresponding RouteDTO
  // This require 2 calls to MongoDB database
  Future getTimesByCity(Map params) async {

    if (params.length == 0 ) {
      return new List(); // return an empty list
    }

    Map queryTime = {
      'arrival': params['cityArrival'],
      'departure': params['cityDepart']
    };
    // Get arrival and departure times per City

    List<TimeDTO> time_dtos;
    // time_dtos contains the list times for Depart_Arrival
    time_dtos = await _mongo.readCollectionByType(TimeDTO, queryTime);

    // get the routes
    Map queryRoutes = {
      'route': params['cityDepart'] + '_' + params['cityArrival']
    };

    return _mongo
        .readCollectionByType(RouteDTO, queryRoutes)
        .then((List route_dtos) {
      // rdtos is the list of routes Key = Depart_Arrival
      // assign the fisrt route_dtos  to each time_dto
      time_dtos
          .forEach((TimeDTO time_dto) => time_dto.route = route_dtos.first);
      return time_dtos;
    });
  }

  //getTimesByFlightNumber
  Future getTimesByFlightNumber(Map params) async {
    List<TimeDTO> time_dtos;
    var queryFligth = {'flight': int.parse(params['flight'])};
    time_dtos = await _mongo.readCollectionByType(TimeDTO, queryFligth);
    var queryRoute = {
      'route': time_dtos.first.departure + "_" + time_dtos.first.arrival
    };
    return _mongo
        .readCollectionByType(RouteDTO, queryRoute)
        .then((List route_dtos) {
      // assign a route to every flight with fligh number
      time_dtos
          .forEach((TimeDTO time_dto) => time_dto.route = route_dtos.first);
      return time_dtos;
    });
  }
}
