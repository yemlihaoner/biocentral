import 'package:biocentral/sdk/biocentral_sdk.dart';
import 'package:fpdart/fpdart.dart';

import '../model/levenshtein_distance.dart';
import 'protein_analysis_api.dart';

class ProteinAnalysisClient extends BiocentralClient {
  ProteinAnalysisClient(super.baseUrl);

  Future<Either<BiocentralException, Map<String, Map<String, LevenshteinDistance>>>> calculateLevenshteinDistance(
      String databaseHash) async {
    final responseEither =
        await doPostRequest(ProteinAnalysisAPIEndpoints.levenshteinDistanceEndpoint, {"database_hash": databaseHash});
    return left(BiocentralParsingException(message: "NOT IMPLEMENTED YET"));
  }

  @override
  String getServiceName() {
    return "data_analysis";
  }
}