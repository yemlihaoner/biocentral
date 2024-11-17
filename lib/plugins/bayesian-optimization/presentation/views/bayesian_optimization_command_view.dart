import 'package:bio_flutter/bio_flutter.dart';
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

  @override
  Widget build(BuildContext context) {
    // final bayesianOptimizationCommandBloc =
    //     BlocProvider.of<BayesianOptimizationCommandBloc>(context);
    return BiocentralCommandBar(
      commands: [
        BiocentralTooltip(
          message: "Get meaningful representations for your data",
          child: BiocentralButton(
            label: "Calculate embeddings..",
            iconData: Icons.calendar_month_rounded,
            requiredServices: const ["embeddings_service"],
            onTap: () {
              // Add your onTap logic here
            },
          ),
        ),
        BiocentralTooltip(
          message: "Perform UMAP dimensionality reduction on your embeddings",
          child: BiocentralButton(
            label: "Calculate UMAP..",
            iconData: Icons.auto_graph,
            requiredServices: const ["embeddings_service"],
            onTap: () {
              // Add your onTap logic here
            },
          ),
        ),
      ],
    );
  }
}
