import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/marketplace_service.dart';

// Events
abstract class MarketplaceEvent extends Equatable {
  const MarketplaceEvent();
  @override
  List<Object?> get props => [];
}

class LoadPrograms extends MarketplaceEvent {
  final String? categoryId;
  final String? search;
  const LoadPrograms({this.categoryId, this.search});
  @override
  List<Object?> get props => [categoryId, search];
}

class LoadProgramDetail extends MarketplaceEvent {
  final String programId;
  const LoadProgramDetail({required this.programId});
  @override
  List<Object?> get props => [programId];
}

class PurchaseProgram extends MarketplaceEvent {
  final String programId;
  const PurchaseProgram({required this.programId});
  @override
  List<Object?> get props => [programId];
}

class LoadProgramContent extends MarketplaceEvent {
  final String programId;
  const LoadProgramContent({required this.programId});
  @override
  List<Object?> get props => [programId];
}

class LoadMyPurchases extends MarketplaceEvent {}

// States
abstract class MarketplaceState extends Equatable {
  const MarketplaceState();
  @override
  List<Object?> get props => [];
}

class MarketplaceInitial extends MarketplaceState {}

class MarketplaceLoading extends MarketplaceState {}

class MarketplaceProgramsLoaded extends MarketplaceState {
  final List<MarketplaceProgram> programs;
  const MarketplaceProgramsLoaded({required this.programs});
  @override
  List<Object?> get props => [programs];
}

class MarketplaceProgramDetailLoaded extends MarketplaceState {
  final MarketplaceProgram program;
  final List<ProgramContentItem> content;
  const MarketplaceProgramDetailLoaded({
    required this.program,
    this.content = const [],
  });
  @override
  List<Object?> get props => [program.id, content.length];
}

class MarketplacePurchaseReady extends MarketplaceState {
  final String clientSecret;
  final String amount;
  final String programId;
  const MarketplacePurchaseReady({
    required this.clientSecret,
    required this.amount,
    required this.programId,
  });
  @override
  List<Object?> get props => [clientSecret, programId];
}

class MarketplacePurchasesLoaded extends MarketplaceState {
  final List<Purchase> purchases;
  const MarketplacePurchasesLoaded({required this.purchases});
  @override
  List<Object?> get props => [purchases.length];
}

class MarketplaceError extends MarketplaceState {
  final String message;
  const MarketplaceError({required this.message});
  @override
  List<Object?> get props => [message];
}

// BLoC
class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final MarketplaceService _service = MarketplaceService.instance;

  MarketplaceBloc() : super(MarketplaceInitial()) {
    on<LoadPrograms>(_onLoadPrograms);
    on<LoadProgramDetail>(_onLoadDetail);
    on<PurchaseProgram>(_onPurchase);
    on<LoadProgramContent>(_onLoadContent);
    on<LoadMyPurchases>(_onLoadPurchases);
  }

  Future<void> _onLoadPrograms(
    LoadPrograms event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(MarketplaceLoading());
    try {
      final programs = await _service.getPrograms(
        categoryId: event.categoryId,
        search: event.search,
      );
      emit(MarketplaceProgramsLoaded(programs: programs));
    } on MarketplaceException catch (e) {
      emit(MarketplaceError(message: e.message));
    } catch (e) {
      emit(const MarketplaceError(message: 'Failed to load programs'));
    }
  }

  Future<void> _onLoadDetail(
    LoadProgramDetail event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(MarketplaceLoading());
    try {
      final program = await _service.getProgramDetail(event.programId);
      List<ProgramContentItem> content = [];
      if (program.isPurchased) {
        try {
          content = await _service.getProgramContent(event.programId);
        } catch (_) {}
      }
      emit(MarketplaceProgramDetailLoaded(program: program, content: content));
    } on MarketplaceException catch (e) {
      emit(MarketplaceError(message: e.message));
    } catch (e) {
      emit(const MarketplaceError(message: 'Failed to load program'));
    }
  }

  Future<void> _onPurchase(
    PurchaseProgram event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(MarketplaceLoading());
    try {
      final result = await _service.purchaseProgram(event.programId);
      emit(MarketplacePurchaseReady(
        clientSecret: result['client_secret'],
        amount: result['amount'],
        programId: event.programId,
      ));
    } on MarketplaceException catch (e) {
      emit(MarketplaceError(message: e.message));
    } catch (e) {
      emit(const MarketplaceError(message: 'Purchase failed'));
    }
  }

  Future<void> _onLoadContent(
    LoadProgramContent event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(MarketplaceLoading());
    try {
      final program = await _service.getProgramDetail(event.programId);
      final content = await _service.getProgramContent(event.programId);
      emit(MarketplaceProgramDetailLoaded(program: program, content: content));
    } on MarketplaceException catch (e) {
      emit(MarketplaceError(message: e.message));
    } catch (e) {
      emit(const MarketplaceError(message: 'Failed to load content'));
    }
  }

  Future<void> _onLoadPurchases(
    LoadMyPurchases event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(MarketplaceLoading());
    try {
      final purchases = await _service.getMyPurchases();
      emit(MarketplacePurchasesLoaded(purchases: purchases));
    } on MarketplaceException catch (e) {
      emit(MarketplaceError(message: e.message));
    } catch (e) {
      emit(const MarketplaceError(message: 'Failed to load purchases'));
    }
  }
}
