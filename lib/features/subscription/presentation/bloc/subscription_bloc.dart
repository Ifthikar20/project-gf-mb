import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/subscription_service.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class LoadSubscriptionStatus extends SubscriptionEvent {}

class CreateCheckout extends SubscriptionEvent {
  final String tier;
  const CreateCheckout({required this.tier});
  @override
  List<Object?> get props => [tier];
}

class OpenBillingPortal extends SubscriptionEvent {}

class RefreshSubscription extends SubscriptionEvent {}

// States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final SubscriptionStatus subscription;
  const SubscriptionLoaded({required this.subscription});
  @override
  List<Object?> get props => [subscription.tier, subscription.status];
}

class SubscriptionCheckoutReady extends SubscriptionState {
  final String checkoutUrl;
  final String sessionId;
  const SubscriptionCheckoutReady({
    required this.checkoutUrl,
    required this.sessionId,
  });
  @override
  List<Object?> get props => [checkoutUrl, sessionId];
}

class SubscriptionPortalReady extends SubscriptionState {
  final String portalUrl;
  const SubscriptionPortalReady({required this.portalUrl});
  @override
  List<Object?> get props => [portalUrl];
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError({required this.message});
  @override
  List<Object?> get props => [message];
}

// BLoC
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionService _service = SubscriptionService.instance;
  SubscriptionStatus? _lastStatus;

  SubscriptionBloc() : super(SubscriptionInitial()) {
    on<LoadSubscriptionStatus>(_onLoadStatus);
    on<CreateCheckout>(_onCreateCheckout);
    on<OpenBillingPortal>(_onOpenPortal);
    on<RefreshSubscription>(_onRefresh);
  }

  SubscriptionStatus? get lastStatus => _lastStatus;

  Future<void> _onLoadStatus(
    LoadSubscriptionStatus event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final status = await _service.getStatus();
      _lastStatus = status;
      emit(SubscriptionLoaded(subscription: status));
    } on SubscriptionException catch (e) {
      emit(SubscriptionError(message: e.message));
    } catch (e) {
      emit(SubscriptionError(message: 'Failed to load subscription'));
    }
  }

  Future<void> _onCreateCheckout(
    CreateCheckout event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final result = await _service.createCheckout(event.tier);
      emit(SubscriptionCheckoutReady(
        checkoutUrl: result['checkout_url']!,
        sessionId: result['session_id']!,
      ));
    } on SubscriptionException catch (e) {
      emit(SubscriptionError(message: e.message));
    } catch (e) {
      emit(SubscriptionError(message: 'Failed to start checkout'));
    }
  }

  Future<void> _onOpenPortal(
    OpenBillingPortal event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final url = await _service.openPortal();
      emit(SubscriptionPortalReady(portalUrl: url));
    } on SubscriptionException catch (e) {
      emit(SubscriptionError(message: e.message));
    } catch (e) {
      emit(SubscriptionError(message: 'Failed to open billing portal'));
    }
  }

  Future<void> _onRefresh(
    RefreshSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final status = await _service.getStatus();
      _lastStatus = status;
      emit(SubscriptionLoaded(subscription: status));
    } catch (_) {
      // Silently fail on refresh — keep current state
    }
  }
}
