import 'package:bio_flutter/bio_flutter.dart';
import 'package:biocentral/sdk/biocentral_sdk.dart';

import 'package:biocentral/plugins/ppi/model/ppi_database_test.dart';

class PPIRepository extends BiocentralDatabase<ProteinProteinInteraction> {
  final Map<String, ProteinProteinInteraction> _interactions = {};

  final List<PPIDatabaseTest> _associatedDatasetTests = [];

  PPIRepository(super.biocentralProjectRepository) : super();

  @override
  String getEntityTypeName() {
    return 'ProteinProteinInteraction';
  }

  @override
  void addEntityImpl(ProteinProteinInteraction entity) {
    final String interactionID = entity.getID();
    _interactions[interactionID] = entity;
  }

  @override
  void addAllEntitiesImpl(Iterable<ProteinProteinInteraction> entities) {
    final entityMap = Map.fromEntries(entities.map((entity) => MapEntry(entity.getID(), entity)));
    _interactions.addAll(entityMap);
  }

  @override
  void removeEntityImpl(ProteinProteinInteraction? entity) {
    if (entity != null) {
      final String interactionID = entity.getID();
      _interactions.remove(interactionID);
    }
  }

  @override
  void updateEntityImpl(String id, ProteinProteinInteraction entityUpdated) {
    final String flippedID = ProteinProteinInteraction.flipInteractionID(id);
    if (_interactions.containsKey(id)) {
      _interactions[id] = entityUpdated;
    }
    if (_interactions.containsKey(flippedID)) {
      _interactions.remove(flippedID);
      _interactions[id] = entityUpdated;
    }
  }

  @override
  void clearDatabaseImpl() {
    _interactions.clear();
    _associatedDatasetTests.clear();
  }

  @override
  Set<String> getSystemColumns() {
    return {'id', 'sequence', 'taxonomyID', 'embeddings'};
  }

  @override
  bool containsEntity(String id) {
    final String flippedID = ProteinProteinInteraction.flipInteractionID(id);
    return _interactions.containsKey(id) || _interactions.containsKey(flippedID);
  }

  @override
  List<ProteinProteinInteraction> databaseToList() {
    return List.from(_interactions.values);
  }

  @override
  Map<String, ProteinProteinInteraction> databaseToMap() {
    return Map.from(_interactions);
  }

  @override
  List<Map<String, dynamic>> entitiesAsMaps() {
    return _interactions.values.map((interaction) => interaction.toMap()).toList();
  }

  @override
  ProteinProteinInteraction? getEntityById(String id) {
    final String flippedID = ProteinProteinInteraction.flipInteractionID(id);
    return _interactions[id] ?? _interactions[flippedID];
  }

  @override
  ProteinProteinInteraction? getEntityByRow(int rowIndex) {
    if (rowIndex >= _interactions.length) {
      return null;
    }
    return _interactions.values.toList()[rowIndex];
  }

  Future<int> removeDuplicates() async {
    final Set<String> duplicates = {};
    for (String interactionID in _interactions.keys) {
      final String flippedInteractionID = ProteinProteinInteraction.flipInteractionID(interactionID);
      if (_interactions.containsKey(flippedInteractionID) && !duplicates.contains(interactionID)) {
        duplicates.add(flippedInteractionID);
      }
    }
    for (String duplicate in duplicates) {
      removeEntity(_interactions[duplicate]);
    }

    if (duplicates.isNotEmpty) {
      logger.i('Removed ${duplicates.length} duplicated interactions from interaction database!');
    }
    return duplicates.length;
  }

  /// Updates protein-protein interactions when proteins have been updated
  ///
  /// Interactions that are no longer found because their associated proteins are no longer available are removed
  @override
  void syncFromDatabase(Map<String, BioEntity> entities, DatabaseImportMode importMode) {
    // TODO Improve syncing condition, check for importMode, Future/await?
    if(entities.isEmpty) {
      return;
    }
    if (entities.entries.first.value is Protein) {
      final Map<String, ProteinProteinInteraction> alignedInteractions = databaseToMap();
      for (MapEntry<String, ProteinProteinInteraction> interactionEntry in _interactions.entries) {
        final String interactor1ID = interactionEntry.value.interactor1.id;
        final String interactor2ID = interactionEntry.value.interactor2.id;

        // Both proteins must still be contained in the protein database
        if (entities.containsKey(interactor1ID) && entities.containsKey(interactor2ID)) {
          alignedInteractions[interactionEntry.key] = interactionEntry.value
              .copyWith(interactor1: entities[interactor1ID], interactor2: entities[interactor2ID]);
        } else {
          alignedInteractions.remove(interactionEntry.key);
        }
      }
      clearDatabase();
      addAllEntities(alignedInteractions.values);
    } else if (entities.entries.first.value is ProteinProteinInteraction) {
      importEntities(entities as Map<String, ProteinProteinInteraction>, importMode);
    }
  }

  @override
  Map<String, ProteinProteinInteraction> updateEmbeddings(Map<String, Embedding> newEmbeddings) {
    // TODO Can be ignored at the moment, because embeddings are calculated directly for interactions
    // TODO see (EmbeddingsCombiner)
    return Map.from(_interactions);
  }

  Set<Protein> _getCurrentProteins() {
    return _interactions.values
        .fold({}, (previous, interaction) => previous..addAll([interaction.interactor1, interaction.interactor2]));
  }

  /// Check if proteins have missing sequences
  bool hasMissingSequences() {
    for (Protein protein in _getCurrentProteins()) {
      if (protein.sequence.isEmpty()) {
        return true;
      }
    }
    return false;
  }

  /// Adds a new test if it does not exist yet
  ///
  /// If it does exist, only the test result is updated
  List<PPIDatabaseTest> addFinishedTest(PPIDatabaseTest newTest) {
    bool add = true;
    for (PPIDatabaseTest existingTest in _associatedDatasetTests) {
      if (existingTest == newTest) {
        existingTest.testResult = newTest.testResult;
        add = false;
        break;
      }
    }
    if (add) {
      _associatedDatasetTests.add(newTest);
    }
    return associatedDatasetTests;
  }

  List<PPIDatabaseTest> get associatedDatasetTests => List.from(_associatedDatasetTests);

}
