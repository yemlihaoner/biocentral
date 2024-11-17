import 'package:flutter_bloc/flutter_bloc.dart';

// Define events for the bloc
abstract class BayesianOptimizationHubEvent {}

class BayesianOptimizationHubReloadEvent extends BayesianOptimizationHubEvent {}

// Define states for the bloc
abstract class BayesianOptimizationHubState {}

class BayesianOptimizationHubInitial extends BayesianOptimizationHubState {}

class BayesianOptimizationHubLoaded extends BayesianOptimizationHubState {}

// Define the bloc
class BayesianOptimizationHubBloc extends Bloc<BayesianOptimizationHubEvent, BayesianOptimizationHubState> {
  BayesianOptimizationHubBloc() : super(BayesianOptimizationHubInitial());

  @override
  Stream<BayesianOptimizationHubState> mapEventToState(BayesianOptimizationHubEvent event) async* {
    if (event is BayesianOptimizationHubReloadEvent) {
      yield BayesianOptimizationHubLoaded();
    }
  }
}
