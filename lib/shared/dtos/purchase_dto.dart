part of ticket_schemas;

@Entity()
class PurchaseDTO extends BaseDTO
{

  String collection_key = "Purchases";
  //should be nums

  int flightID;
  int flightLevel;
  String ccn;
  String ccv;
  String bZip;
  String ccType;
  String ccExpiration;

  String pFirstName;
  String pMiddleName;
  String plastname;
  String pEmail;

  String bFirstName;
  String bMiddleName;
  String blastname;
  String bAddress;
  String bCity;
  String bState;
  String bCountry;
  String transactionId;

}

