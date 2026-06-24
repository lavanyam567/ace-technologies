import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../core/services/supabase_service.dart';
import '../../core/utils/url_cleanup.dart';

class AuthProvider extends StateNotifier<AuthState> {
  AuthProvider() : super(AuthState.fromSession(_client.auth.currentSession)) {
    _authSubscription = _client.auth.onAuthStateChange.listen((event) {
      final nextState = AuthState.fromSession(event.session);
      state = nextState;
      if (nextState.isAuthenticated) {
        cleanAuthCallbackUrl();
        Future.microtask(loadProfile);
      }
    });

    if (state.isAuthenticated) {
      Future.microtask(loadProfile);
    }
  }

  static SupabaseClient get _client => Supabase.instance.client;
  late final StreamSubscription<dynamic> _authSubscription;

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await SupabaseService.instance.signIn(
        email: email,
        password: password,
      );
      state = AuthState.fromUser(response.user);
      await loadProfile();
      return state.isAuthenticated;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> signup(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await SupabaseService.instance.signUp(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      state = AuthState.fromUser(
        response.user,
        fallbackName: name,
      ).copyWith(userPhone: phone);
      await loadProfile();
      return state.isAuthenticated;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final launched = await SupabaseService.instance.signInWithGoogle();
      state = state.copyWith(isLoading: false);
      return launched;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await SupabaseService.instance.signOut();
    state = const AuthState();
  }

  Future<void> loadProfile() async {
    if (!state.isAuthenticated) return;

    state = state.copyWith(isProfileLoading: true, clearError: true);
    try {
      final profile = await SupabaseService.instance.fetchCurrentProfile();
      final user = Supabase.instance.client.auth.currentUser;
      final metadata = user?.userMetadata ?? {};
      state = state.copyWith(
        isProfileLoading: false,
        userName:
            profile?['full_name'] as String? ??
            metadata['full_name'] as String? ??
            state.userName,
        userPhone:
            profile?['phone'] as String? ??
            metadata['phone'] as String? ??
            state.userPhone,
        profileImageUrl:
            profile?['avatar_url'] as String? ??
            metadata['avatar_url'] as String? ??
            state.profileImageUrl,
        role: profile?['role'] as String? ?? state.role,
      );
    } catch (error) {
      state = state.copyWith(isProfileLoading: false, error: error.toString());
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? profileImageUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await SupabaseService.instance.updateCurrentProfile(
        name: name,
        phone: phone,
        avatarUrl: profileImageUrl,
      );
      final user = Supabase.instance.client.auth.currentUser;
      state = AuthState.fromUser(user, fallbackName: name).copyWith(
        isLoading: false,
        userName: profile['full_name'] as String? ?? name,
        userPhone: profile['phone'] as String? ?? phone,
        profileImageUrl: profile['avatar_url'] as String? ?? profileImageUrl,
      );
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }
}

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isProfileLoading;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? profileImageUrl;
  final String role;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isProfileLoading = false,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.profileImageUrl,
    this.role = 'customer',
    this.error,
  });

  String get name => userName ?? '';
  String get email => userEmail ?? '';
  String get phone => userPhone?.isNotEmpty == true ? userPhone! : '';
  String get avatarUrl => profileImageUrl ?? '';
  bool get isAdmin => role == 'admin';

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isProfileLoading,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? profileImageUrl,
    String? role,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isProfileLoading: isProfileLoading ?? this.isProfileLoading,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      error: clearError ? null : error ?? this.error,
    );
  }

  factory AuthState.fromSession(Session? session) {
    return AuthState.fromUser(session?.user);
  }

  factory AuthState.fromUser(User? user, {String? fallbackName}) {
    if (user == null) {
      return const AuthState();
    }
    final metadata = user.userMetadata ?? {};
    return AuthState(
      isAuthenticated: true,
      userName: metadata['full_name'] as String? ?? fallbackName ?? '',
      userPhone: metadata['phone'] as String?,
      profileImageUrl: metadata['avatar_url'] as String?,
      role: metadata['role'] as String? ?? 'customer',
      userEmail: user.email,
    );
  }
}

final authProvider = StateNotifierProvider<AuthProvider, AuthState>((ref) {
  return AuthProvider();
});
