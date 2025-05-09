import 'dart:convert';

import 'package:bio_flutter/bio_flutter.dart';
import 'package:biocentral/sdk/biocentral_sdk.dart';
import 'package:fpdart/fpdart.dart';

import 'package:biocentral/plugins/proteins/data/protein_service_api.dart';

final class ProteinClientFactory extends BiocentralClientFactory<ProteinClient> {
  @override
  ProteinClient create(BiocentralServerData? server, BiocentralHubServerClient hubServerClient) {
    return ProteinClient(server, hubServerClient);
  }
}

class ProteinClient extends BiocentralClient {
  const ProteinClient(super._server, super._hubServerClient);

  Future<Either<BiocentralException, Map<int, Taxonomy>>> retrieveTaxonomy(Set<int> taxonomyIDs) async {
    final Map<String, String> body = {'taxonomy': jsonEncode(taxonomyIDs.map((e) => e.toString()).toList())};
    final responseEither = await doPostRequest(ProteinServiceEndpoints.retrieveTaxonomy, body);
    return responseEither.flatMap((responseMap) => parseTaxonomy(responseMap['taxonomy']));
  }

  @override
  String getServiceName() {
    return 'protein_service';
  }
}
