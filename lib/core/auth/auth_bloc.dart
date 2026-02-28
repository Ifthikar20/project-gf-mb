import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/auth_service.dart';
import '../services/personalization_service.dart';
import '../utils/error_messages.dart';

// ============================================
// Events
// ============================================

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  const AuthLoginRequested({required this.email, required this.password});
  
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
  });
  
  @override
  List<Object?> get props => [email, password, fullName];
}

class AuthLogoutRequested extends AuthEvent {}

/// Event triggered when OAuth completes successfully
class AuthUserChanged extends AuthEvent {
  final User user;
  
  const AuthUserChanged(this.user);
  
  @override
  List<Object?> get props => [user];
}

/// Event triggered when onboarding is completed or skipped
class AuthOnboardingCompleted extends AuthEvent {}

// ============================================
// States
// ============================================

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  
  const AuthAuthenticated(this.user);
  
  @override
  List<Object?> get props => [user];
}

/// User is authenticated but has not completed onboarding
class AuthNeedsOnboarding extends AuthState {
  final User user;
  
  const AuthNeedsOnboarding(this.user);
  
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// ============================================
// BLoC
// ============================================

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final PersonalizationService _personalizationService;
  
  AuthBloc({AuthService? authService, PersonalizationService? personalizationService}) 
      : _authService = authService ?? AuthService.instance,
        _personalizationService = personalizationService ?? PersonalizationService.instance,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);
  }
  
  /// Handle OAuth success — check onboarding
  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    await _emitAuthenticatedOrOnboarding(event.user, emit);
  }
  
  /// Handle onboarding completed — transition to AuthAuthenticated
  void _onOnboardingCompleted(
    AuthOnboardingCompleted event,
    Emitter<AuthState> emit,
  ) {
    final currentState = state;
    if (currentState is AuthNeedsOnboarding) {
      emit(AuthAuthenticated(currentState.user));
    } else if (currentState is AuthAuthenticated) {
      // Already authenticated, no-op
    }
  }
  
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Try to restore session from stored tokens
      final user = await _authService.tryRestoreSession();
      if (user != null) {
        await _emitAuthenticatedOrOnboarding(user, emit);
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('\n [AUTH BLOC] Login event received');
    print(' Email: ${event.email}');
    
    emit(AuthLoading());
    
    try {
      final user = await _authService.login(
        email: event.email,
        password: event.password,
      );
      
      print(' [AUTH BLOC] Login successful, checking onboarding...');
      await _emitAuthenticatedOrOnboarding(user, emit);
    } on AuthException catch (e) {
      final friendlyMessage = ErrorMessages.formatAuthError(
        e,
        statusCode: e.statusCode,
        code: e.code,
      );
      emit(AuthError(friendlyMessage));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authService.register(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );
      // New users always need onboarding
      emit(AuthNeedsOnboarding(user));
    } on AuthException catch (e) {
      final friendlyMessage = ErrorMessages.formatAuthError(
        e,
        statusCode: e.statusCode,
        code: e.code,
      );
      emit(AuthError(friendlyMessage));
    } catch (e) {
      final friendlyMessage = ErrorMessages.formatAuthError(e);
      emit(AuthError(friendlyMessage));
    }
  }
  
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authService.logout();
    emit(AuthUnauthenticated());
  }
  
  /// Check onboarding status and emit the appropriate state
  Future<void> _emitAuthenticatedOrOnboarding(
    User user,
    Emitter<AuthState> emit,
  ) async {
    try {
      final completed = await _personalizationService.isOnboardingCompleted();
      if (completed) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthNeedsOnboarding(user));
      }
    } catch (e) {
      // If check fails, let them through (don't block on optional onboarding)
      print(' Onboarding check failed, proceeding: $e');
      emit(AuthAuthenticated(user));
    }
  }
}
