library tiket_controler;

import 'package:shelf/shelf.dart';
import 'package:shelf_path/shelf_path.dart' as path;
import 'package:dartson/dartson.dart';
import 'ticketing_model.dart';
import 'dart:async';
import 'dart:convert';

TicketingModel model = new TicketingModel();

Dartson converter = new Dartson.JSON();

// Path parameters
// Path parameters are derived from the structure of a URI.
// A URI can contain multiple types of path parameters,
// including segmented parameters and query parameters.
// convert  Path  parameters  into  Dart Map
// GET /user/123456/comments?stars=5
Map getPathParams(Request request, Map payload) {
  Map params = path.getPathParameters(request);
  params.forEach((key, val) {
    payload[key] = val;
  });
  return payload;
}

// Post parameters
// convert post parameters  into  Dart Map
Future<Map> getPostParams(Request request) {
  return request.readAsString().then((String body) {
    return body.isNotEmpty ? JSON.decode(body) : {};
  });
}

// You need two functions to properly format the outbound response:
// _ dartsonListToJson() and makeResponse() .
// Let’s take a look at the Dartson method first.

// Format outboud response Object
String _dartsonListToJson(payload) {
  var encodable = converter.serialize(payload);
  return JSON.encode(encodable);
}

// The Response class exposes a series of factory constructors, including ok() ,
// forbidden() , found() , internalServerError() ,
// and other HTTP response statuses.
Future<Response> makeResponse(String json) async {
  var response = new Response.ok(json);
  return response;
}

// Generic Json handler
Future<Response> _genericJsonHandler(Function getter, Request request) {
  return getPostParams(request)
      .then((params) => getPathParams(request, params))
      .then((payload) => getter(payload))
      .then((list) => _dartsonListToJson(list))
      .then(makeResponse);
}

Future<Response> handleCities(Request request) {
  return _genericJsonHandler(model.getAllCities, request);
}

Future<Response> handleTimesCity(Request request) {
  return _genericJsonHandler(model.getTimesByCity, request);
}

Future<Response> handleFlightNumber(Request request) {
  return _genericJsonHandler(model.getTimesByFlightNumber, request);
}

Future<Response> handleTimes(Request request) {
  return _genericJsonHandler(model.getAllTimes, request);
}

Future<Response> handlePurchase(Request request) {
  return _genericJsonHandler(model.createPurchase, request);
}
