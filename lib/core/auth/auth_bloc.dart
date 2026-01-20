import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/auth_service.dart';

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
  
  AuthBloc({AuthService? authService}) 
      : _authService = authService ?? AuthService.instance,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserChanged>(_onUserChanged);
  }
  
  /// Handle OAuth success
  void _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthAuthenticated(event.user));
  }
  
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Try to restore session from stored tokens first
      final user = await _authService.tryRestoreSession();
      if (user != null) {
        emit(AuthAuthenticated(user));
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
    print('\n📱 [AUTH BLOC] Login event received');
    print('📧 Email: ${event.email}');
    print('📍 Location: AuthBloc._onLoginRequested()');
    
    print('\n🔄 [AUTH BLOC] Emitting AuthLoading state');
    emit(AuthLoading());
    
    try {
      print('🔐 [AUTH BLOC] Calling AuthService.login()...');
      final user = await _authService.login(
        email: event.email,
        password: event.password,
      );
      
      print('✅ [AUTH BLOC] Login successful, emitting AuthAuthenticated state');
      print('👤 User: ${user.email}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      print('\n❌ [AUTH BLOC] Login failed in BLoC layer');
      print('📍 Location: AuthBloc._onLoginRequested() - catch block');
      print('🔍 Error Type: ${e.runtimeType}');
      print('💬 Error: $e');
      print('🔄 [AUTH BLOC] Emitting AuthError state\n');
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
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
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
}
