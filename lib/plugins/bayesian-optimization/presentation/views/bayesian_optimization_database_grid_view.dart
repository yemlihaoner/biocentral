import 'package:biocentral/plugins/bayesian-optimization/model/bayesian_optimization_training_result.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

/// A widget that displays Bayesian optimization results in a grid format.
/// Shows protein sequences, scores, uncertainties, and other metrics in a sortable and filterable table.
class BayesianOptimizationDatabaseGridView extends StatefulWidget {
  /// The training results data to be displayed
  final BayesianOptimizationTrainingResult? data;

  const BayesianOptimizationDatabaseGridView({
    this.data,
    super.key,
  });

  @override
  State<BayesianOptimizationDatabaseGridView> createState() => _BayesianOptimizationDatabaseGridViewState();
}

class _BayesianOptimizationDatabaseGridViewState extends State<BayesianOptimizationDatabaseGridView> {
  /// Default columns configuration for the grid
  static final List<PlutoColumn> _defaultBOColumns = <PlutoColumn>[
    _createColumn(
      title: 'Protein ID',
      field: 'proteinId',
      type: PlutoColumnType.text(),
      footerType: PlutoAggregateColumnType.count,
      footerTitle: 'N',
      footerColor: Colors.green,
    ),
    _createColumn(
      title: 'Score',
      field: 'score',
      type: PlutoColumnType.number(format: '#,###.###'),
      footerType: PlutoAggregateColumnType.count,
      footerTitle: 'Missing',
      footerColor: Colors.red,
    ),
    _createColumn(
      title: 'Sequence',
      field: 'sequence',
      type: PlutoColumnType.text(),
      footerType: PlutoAggregateColumnType.count,
      footerTitle: 'Missing',
      footerColor: Colors.red,
    ),
    _createColumn(
      title: 'Uncertainty',
      field: 'uncertainty',
      type: PlutoColumnType.number(format: '#,###.###'),
      footerType: PlutoAggregateColumnType.count,
      footerTitle: 'Missing',
      footerColor: Colors.red,
    ),
    _createColumn(
      title: 'Mean',
      field: 'mean',
      type: PlutoColumnType.number(format: '#,###.###'),
      footerType: PlutoAggregateColumnType.count,
      footerTitle: 'Missing',
      footerColor: Colors.red,
    ),
  ];

  /// Grid state manager for handling grid operations
  PlutoGridStateManager? stateManager;

  /// Grid mode configuration
  final PlutoGridMode plutoGridMode = PlutoGridMode.selectWithOneTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double columnWidth = constraints.maxWidth / _defaultBOColumns.length;
          return _buildGrid(columnWidth);
        },
      ),
    );
  }

  /// Builds the main grid widget with configured columns and rows
  Widget _buildGrid(double columnWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PlutoGrid(
        mode: plutoGridMode,
        columns: buildColumns(columnWidth),
        rows: buildRows(),
        onLoaded: _handleGridLoaded,
      ),
    );
  }

  /// Handles grid initialization and setup
  void _handleGridLoaded(PlutoGridOnLoadedEvent event) {
    stateManager ??= event.stateManager;
    stateManager!.setShowColumnFilter(true);
  }

  /// Creates a column with the specified configuration
  static PlutoColumn _createColumn({
    required String title,
    required String field,
    required PlutoColumnType type,
    required PlutoAggregateColumnType footerType,
    required String footerTitle,
    required Color footerColor,
  }) {
    return PlutoColumn(
      title: title,
      field: field,
      type: type,
      footerRenderer: (rendererContext) {
        return PlutoAggregateColumnFooter(
          rendererContext: rendererContext,
          type: footerType,
          filter: (PlutoCell plutoCell) => plutoCell.value == -1,
          format: '#',
          alignment: Alignment.center,
          titleSpanBuilder: (text) {
            return [
              TextSpan(
                text: footerTitle,
                style: TextStyle(color: footerColor),
              ),
              const TextSpan(text: ': '),
              TextSpan(text: text),
            ];
          },
        );
      },
    );
  }

  /// Builds and configures columns with the specified width
  List<PlutoColumn> buildColumns(double columnWidth) {
    final List<PlutoColumn> result = List.from(_defaultBOColumns);
    for (PlutoColumn column in result) {
      column.width = columnWidth;
      column.minWidth = columnWidth;
    }
    return result;
  }

  /// Builds rows from the training results data
  List<PlutoRow> buildRows() {
    if (widget.data?.results == null) {
      return [];
    }

    return widget.data!.results!.map((data) {
      return PlutoRow(
        cells: {
          'proteinId': PlutoCell(value: data.proteinId),
          'score': PlutoCell(value: data.score),
          'sequence': PlutoCell(value: data.sequence),
          'uncertainty': PlutoCell(value: data.uncertainty),
          'mean': PlutoCell(value: data.mean),
        },
      );
    }).toList();
  }
}
