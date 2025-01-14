import 'package:bio_flutter/bio_flutter.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tutorial_system/tutorial_system.dart';

import '../data/biocentral_client.dart';
import '../domain/biocentral_column_wizard_repository.dart';
import '../domain/biocentral_database_repository.dart';
import '../domain/biocentral_project_repository.dart';
import '../model/column_wizard_abstract.dart';
import '../util/size_config.dart';


abstract class BiocentralPlugin with TypeNameMixin {
  final EventBus eventBus;

  BiocentralPlugin(this.eventBus);

  String getShortDescription();

  Set<Type> getDependencies() {
    // No dependencies by default
    return {};
  }

  Widget getIcon();

  Widget getTab();

  Widget getCommandView(BuildContext context);

  Widget getScreenView(BuildContext context);

  List<BlocProvider> getListeningBlocs(BuildContext context);

  BiocentralClientRepository getBiocentralClientRepository(BuildContext context) {
    return context.read<BiocentralClientRepository>();
  }

  BiocentralProjectRepository getBiocentralProjectRepository(BuildContext context) {
    return context.read<BiocentralProjectRepository>();
  }

  BiocentralDatabaseRepository getBiocentralDatabaseRepository(BuildContext context) {
    return context.read<BiocentralDatabaseRepository>();
  }

  BiocentralColumnWizardRepository getBiocentralColumnWizardRepository(BuildContext context) {
    return context.read<BiocentralColumnWizardRepository>();
  }

  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: getListeningBlocs(context),
      child: Column(mainAxisSize: MainAxisSize.max, children: [
        Flexible(
          flex: 5,
          child: getCommandView(context),
        ),
        Expanded(
            flex: 14,
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal(context) * 0.75, vertical: 1),
                child: getScreenView(context))),
      ]),
    );
  }
}

mixin BiocentralClientPluginMixin<T extends BiocentralClient> on BiocentralPlugin {
  BiocentralClientFactory<T> createClientFactory();
}

mixin BiocentralDatabasePluginMixin<T> on BiocentralPlugin {
  T createListeningDatabase();

  RepositoryProvider<T> createRepositoryProvider(T database) {
    return RepositoryProvider<T>.value(value: database);
  }

  T getDatabase(BuildContext context) {
    return context.read<T>();
  }
}

mixin BiocentralColumnWizardPluginMixin on BiocentralPlugin {
  List<ColumnWizardFactory> createColumnWizardFactories();
}

mixin BiocentralTutorialPluginMixin on BiocentralPlugin {
  List<Tutorial> getTutorials();
}
