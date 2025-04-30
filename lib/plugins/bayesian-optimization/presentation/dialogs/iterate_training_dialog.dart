import 'package:biocentral/plugins/bayesian-optimization/model/bayesian_optimization_training_result.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

class IterateTrainingDialog extends StatefulWidget {
  final BayesianOptimizationTrainingResult currentResult;
  final Function(List<bool>) onStartIteration;

  const IterateTrainingDialog({
    required this.currentResult,
    required this.onStartIteration,
    super.key,
  });

  @override
  State<IterateTrainingDialog> createState() => _IterateTrainingDialogState();
}

class _IterateTrainingDialogState extends State<IterateTrainingDialog> {
  late PlutoGridStateManager stateManager;
  late BayesianOptimizationTrainingResult editedResult;
  List<bool> boolList = [];

  @override
  void initState() {
    super.initState();
    editedResult = widget.currentResult;
    boolList = List.filled(editedResult.results?.length ?? 0, false);
  }

  List<PlutoColumn> buildColumns() {
    return [
      PlutoColumn(
        title: 'Select',
        field: 'select',
        type: PlutoColumnType.select(['true', 'false']),
        width: 80,
      ),
      PlutoColumn(
        title: 'Protein ID',
        field: 'proteinId',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Score',
        field: 'score',
        type: PlutoColumnType.number(format: '#,###.############'),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actual Value',
        field: 'actualValue',
        type: PlutoColumnType.number(format: '#,###.############'),
        width: 150,
        enableEditingMode: false,
      ),
    ];
  }

  List<PlutoRow> buildRows() {
    var i = 0;
    return editedResult.results!.map((result) {
      return PlutoRow(
        cells: {
          'select': PlutoCell(value: boolList[i] ? 'true' : 'false'),
          'proteinId': PlutoCell(value: result.proteinId),
          'score': PlutoCell(value: result.score),
          'actualValue': PlutoCell(value: editedResult.actualValues?[i++]),
        },
      );
    }).toList();
  }

  void handleCellValueChanged(PlutoGridOnChangedEvent event) {
    if (event.column.field == 'select') {
      final rowIndex = event.rowIdx;
      final newValue = event.value == 'true';

      setState(() {
        boolList[rowIndex] = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select Proteins for Training',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PlutoGrid(
                columns: buildColumns(),
                rows: buildRows(),
                onChanged: handleCellValueChanged,
                onLoaded: (event) {
                  stateManager = event.stateManager;
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    widget.onStartIteration(boolList);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Start Training Iteration'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
