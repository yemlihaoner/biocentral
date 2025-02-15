import 'package:biocentral/sdk/biocentral_sdk.dart';

final class BayesianOptimizationClientFactory
    extends BiocentralClientFactory<BayesianOptimizationClient> {
  @override
  BayesianOptimizationClient create(
    BiocentralServerData? server,
    BiocentralHubServerClient hubServerClient,
  ) {
    return BayesianOptimizationClient(server, hubServerClient);
  }
}

class BayesianOptimizationClient extends BiocentralClient {
  BayesianOptimizationClient(super._server, super._hubServerClient);

  @override
  String getServiceName() {
    return 'bayesian_optimization_service';
  }
}
