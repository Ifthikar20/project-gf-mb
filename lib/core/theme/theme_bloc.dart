import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme Mode Enum
enum AppThemeMode { vintage, classicDark }

// Events
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();
  @override
  List<Object> get props => [];
}

class LoadTheme extends ThemeEvent {}

class ToggleTheme extends ThemeEvent {}

class SetTheme extends ThemeEvent {
  final AppThemeMode mode;
  const SetTheme(this.mode);
  @override
  List<Object> get props => [mode];
}

// State
class ThemeState extends Equatable {
  final AppThemeMode mode;
  
  const ThemeState({this.mode = AppThemeMode.vintage});
  
  ThemeState copyWith({AppThemeMode? mode}) {
    return ThemeState(mode: mode ?? this.mode);
  }
  
  bool get isVintage => mode == AppThemeMode.vintage;
  bool get isClassicDark => mode == AppThemeMode.classicDark;
  
  @override
  List<Object> get props => [mode];
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'app_theme_mode';
  
  ThemeBloc() : super(const ThemeState()) {
    on<LoadTheme>(_onLoadTheme);
    on<ToggleTheme>(_onToggleTheme);
    on<SetTheme>(_onSetTheme);
  }
  
  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey);
      if (themeName == 'classicDark') {
        emit(state.copyWith(mode: AppThemeMode.classicDark));
      } else {
        emit(state.copyWith(mode: AppThemeMode.vintage));
      }
    } catch (_) {
      // Default to vintage on error
      emit(state.copyWith(mode: AppThemeMode.vintage));
    }
  }
  
  Future<void> _onToggleTheme(ToggleTheme event, Emitter<ThemeState> emit) async {
    final newMode = state.isVintage ? AppThemeMode.classicDark : AppThemeMode.vintage;
    await _saveTheme(newMode);
    emit(state.copyWith(mode: newMode));
  }
  
  Future<void> _onSetTheme(SetTheme event, Emitter<ThemeState> emit) async {
    await _saveTheme(event.mode);
    emit(state.copyWith(mode: event.mode));
  }
  
  Future<void> _saveTheme(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (_) {
      // Silently fail
    }
  }
}
