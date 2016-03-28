part of ticket_schemas;

class BaseDTO {
  String id; // unique MongoDB ID
  String collection_key; // we are modelling MongoDB documents and all documents belong to a collection
}