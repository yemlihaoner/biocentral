import 'package:bio_flutter/bio_flutter.dart';
import 'package:biocentral/sdk/biocentral_sdk.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class BiocentralBloc<Event, T extends BiocentralCommandState<T>> extends Bloc<Event, T> {
  final EventBus _eventBus;

  BiocentralBloc(super.initialState, this._eventBus) {
    stream.listen((T state) {
      _eventBus.fire(BiocentralCommandStateChangedEvent(state));
    });
  }

  Future<void> _setIdleAfterCommandExecution(emit) async {
    await Future.delayed(Constants.showLastStateMessageDuration).whenComplete(() => emit(state.setIdle()));
  }

  @override
  void on<E extends Event>(
    EventHandler<E, T> handler, {
    EventTransformer<E>? transformer,
  }) {
    wrappedHandler(E event, Emitter<T> emit) async {
      await handler(event, emit);
      _eventBus.fire(BiocentralCommandExecutedEvent());
      await _setIdleAfterCommandExecution(emit);
    }

    super.on<E>(wrappedHandler, transformer: transformer);
  }
}

abstract class BiocentralSyncBloc<Event, T extends BiocentralCommandState<T>> extends BiocentralBloc<Event, T> {
  BiocentralSyncBloc(super.initialState, super._eventBus);

  void syncWithDatabases(Map<String, BioEntity> entities,
      {DatabaseImportMode importMode = DatabaseImportMode.defaultMode}) async {
    _eventBus.fire(BiocentralDatabaseSyncEvent(entities, importMode));
  }
}

abstract class BiocentralUpdateBloc<Event, T extends BiocentralCommandState<T>> extends BiocentralBloc<Event, T> {
  BiocentralUpdateBloc(super.initialState, super._eventBus);

  void updateDatabases() async {
    _eventBus.fire(BiocentralDatabaseUpdatedEvent());
  }
}