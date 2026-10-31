import 'package:cloud_functions/cloud_functions.dart';

const clearwayFunctionsRegion = 'asia-south1';

FirebaseFunctions get clearwayFunctions =>
    FirebaseFunctions.instanceFor(region: clearwayFunctionsRegion);
