import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
// import 'package:shelf_route/shelf_route.dart';
import 'package:mojito/mojito.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:shelf_static/shelf_static.dart';
import 'ticketing_controler.dart' as controller;
import 'dart:mirrors';

// POST to Create
// GET to read
// PUT to Update
// DELETE to delete
Map CORSHeader = {
  'content-type': 'text/json',
  'Access-Control-Allow-Origin': "*",
  'Access-Control-Allow-Headers': "Origin,X-Request-With, Content-Type, Accept",
  'Access-Control-Allow-Methods': "POST,GET,PUT,DELETE,OPTIONS",
};

Response reqHandler(Request request) {
  // The request handler is the focal point for this piece of middleware
  // all inbound requets inspect the HTTP method

  if (request.method == "OPTIONS") {
    // send back an immediate response with the CORS object appended to the headers
    return new Response.ok(null, headers: CORSHeader);
  }
  // sending back null allow the next handler in the chain to inspect the request
  return null;
}

Response respHandler(Response response) {
  /* The response handler is called on the other end of the chain
    when the last Request handler is called
    all other response handlers are executed in a FILO  order
    in the case of the CORS response handler, you want to ensure that
    all HTTP responses have the appropriated CORS object in the HTTP Header
    You leverage the response.change() method to append your existing CORS
    object on the message Header */

  return response.change(headers: CORSHeader);
}

Response echo(Request request) {
  return new Response.ok('Request for "${request.url}"');
}

void main() {
  // Create a static file handler
  var path = Platform.script.toFilePath();
  var currentDirectory = dirname(path);
  var fullPath = join(currentDirectory, '..', 'build/web');
  // create a static file handler
  Handler fHandler =
      createStaticHandler(fullPath, defaultDocument: 'index.html');

  //  Intanciate a ROUTER  Object
  Router primaryRouter = router();

  //any route will be prefixed by tickets
  // Router api = primaryRouter.child('/tickets');
  // /tickets/flight/   /tickets/cities  /tickets/times /tickets/purchase
  // test  Routes
  // curl http://localhost:8080/tickets/flight/1016
  // curl http://localhost:8080/tickets/cities
  // curl -H "Content-Type: application/json" -X POST -d '{"cityDepart":"SFO", "cityArrival":"SAN","dateDepart":"2016-12-31","dateArrival":"2016-12-31"}' http://localhost:8082/tickets/times
  //
  Router api = primaryRouter.child('/tickets')
  ..add('/flight/{flight}', ['GET'], controller.handleFlightNumber)
  ..add('/cities', ['GET'], controller.handleCities)
  ..add('/times', ['POST'], controller.handleTimesCity)
  ..add('/purchase', ['POST'], controller.handlePurchase);

  printRoutes(api);

  // print('${api.fullPaths}');


  // create  Middlewares
  Middleware logreq = logRequests();
  Middleware corsMiddleWare = createMiddleware(
      requestHandler: reqHandler, responseHandler: respHandler);

  Pipeline pl = new Pipeline();

  // add  the corsMiddleWare and logreq  middlewares to the chain

 //  pl.addMiddleware(corsMiddleWare).addMiddleware(logreq) ;

  // add echo middleware handler to the pipeline
  // Handler handler = pl.addHandler(echo);

  // Add a Router to the end of the chain Chain
  // By making the router the final handler, you are ensuring
  // that all middleware Request actions occur prior to the business logic,
  // and that all middleware Response actions occur after our business logic
  // This is a key distinction between middleware and router.
  // Middleware occurs on all HTTP occurences whereares a router handler
  // gets activated only if there is matching URI pattern

  Handler application = primaryRouter.handler;

  Handler apiHandler = pl
    .addMiddleware(corsMiddleWare)
    .addMiddleware(logreq)
    .addHandler(application);

  // using multiple handlers
  // a cascade is a way to group multiple pipelines
  // a cascade will be executed as a FIFO queue

   Cascade cc = new Cascade().add(apiHandler).add(fHandler);


  io.serve(cc.handler, '0.0.0.0', 8082).then((server) {
    print('serving at http://${server.address.host}:${server.port}');
  });
}
