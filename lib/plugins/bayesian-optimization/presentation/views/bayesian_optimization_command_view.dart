import 'package:bio_flutter/bio_flutter.dart';
import 'package:biocentral/biocentral/presentation/dialogs/welcome_dialog.dart';
import 'package:biocentral/plugins/bayesian-optimization/presentation/dialogs/StartBoTrainingDialog.dart';
import 'package:biocentral/sdk/biocentral_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BayesianOptimizationCommandView extends StatefulWidget {
  const BayesianOptimizationCommandView({super.key});

  @override
  State<BayesianOptimizationCommandView> createState() => _BayesianOptimizationCommandViewState();
}

class _BayesianOptimizationCommandViewState extends State<BayesianOptimizationCommandView> {
  @override
  void initState() {
    super.initState();
  }

  void openStartTrainingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const StartBoTrainingDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // final bayesianOptimizationCommandBloc =
    //     BlocProvider.of<BayesianOptimizationCommandBloc>(context);
    return BiocentralCommandBar(
      commands: [
        BiocentralTooltip(
          message: 'Start new training',
          child: BiocentralButton(
            label: 'Start new training',
            iconData: Icons.add,
            requiredServices: const [],
            onTap: () {
              // Add your onTap logic here
              openStartTrainingDialog();
            },
          ),
        ),
        BiocentralTooltip(
          message: "Iterate on training",
          child: BiocentralButton(
            label: "Iterate on training",
            iconData: Icons.model_training,
            requiredServices: const [],
            onTap: () {
              // Add your onTap logic here
            },
          ),
        ),
      ],
    );
  }
}
