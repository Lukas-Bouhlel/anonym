import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../models/user_model.dart';
import '../services/auth_repository.dart';
import '../utils/api_error_parser.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository) {
    _repository.setSessionExpiredHandler(_handleSessionExpired);
    bootstrap();
  }

  final AuthRepository _repository;

  UserModel? _user;
  bool _isBootstrapping = true;
  bool _isBusy = false;
  String? _errorMessage;
  String? _infoMessage;
  int? _retryAfterSeconds;
  int _authMutationVersion = 0;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isBootstrapping => _isBootstrapping;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  int? get retryAfterSeconds => _retryAfterSeconds;

  Future<void> bootstrap() async {
    final bootstrapVersion = _authMutationVersion;
    _isBootstrapping = true;
    if (kDebugMode) {
      debugPrint(
        '[AUTH][bootstrap:start] v=$bootstrapVersion currentV=$_authMutationVersion',
      );
    }
    notifyListeners();

    try {
      await _repository.hydrateSession();
      final me = await _repository.me();
      if (bootstrapVersion != _authMutationVersion) {
        if (kDebugMode) {
          debugPrint(
            '[AUTH][bootstrap:ignored-success] v=$bootstrapVersion currentV=$_authMutationVersion',
          );
        }
        return;
      }
      _user = me;
      _errorMessage = null;
      if (kDebugMode) {
        debugPrint('[AUTH][bootstrap:success] user=${_user?.id}');
      }
    } catch (error) {
      if (bootstrapVersion != _authMutationVersion) {
        if (kDebugMode) {
          debugPrint(
            '[AUTH][bootstrap:ignored-error] v=$bootstrapVersion currentV=$_authMutationVersion',
          );
        }
        return;
      }
      _user = null;
      if (_isUnauthorized(error)) {
        await _repository.clearLocalSession();
      }
      if (kDebugMode) {
        debugPrint(
          '[AUTH][bootstrap:error] unauthorized=${_isUnauthorized(error)}',
        );
      }
    } finally {
      _isBootstrapping = false;
      if (kDebugMode) {
        debugPrint(
          '[AUTH][bootstrap:end] v=$bootstrapVersion currentV=$_authMutationVersion loggedIn=$isLoggedIn',
        );
      }
      notifyListeners();
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _setBusy(true);
    _authMutationVersion++;
    _errorMessage = null;
    if (kDebugMode) {
      debugPrint('[AUTH][login:start] v=$_authMutationVersion id=$identifier');
    }

    try {
      _user = await _repository.login(
        identifier: identifier,
        password: password,
      );
      if (kDebugMode) {
        debugPrint('[AUTH][login:success] user=${_user?.id}');
      }
      return true;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(e, fallback: 'Connexion impossible');
      if (kDebugMode) {
        debugPrint('[AUTH][login:error] $_errorMessage');
      }
      return false;
    } finally {
      _setBusy(false);
      if (kDebugMode) {
        debugPrint('[AUTH][login:end] loggedIn=$isLoggedIn');
      }
    }
  }

  Future<bool> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    _authMutationVersion++;
    _errorMessage = null;

    try {
      _user = await _repository.signup(
        username: username,
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Inscription impossible',
      );
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> requestRegisterCode({
    required String email,
    required String username,
    required String password,
  }) async {
    _setBusy(true);
    _errorMessage = null;
    _infoMessage = null;
    _retryAfterSeconds = null;
    try {
      final payload = await _repository.requestRegisterCode(
        email: email,
        username: username,
        password: password,
      );
      final message = payload['message'];
      if (message is String && message.trim().isNotEmpty) {
        _infoMessage = message;
      }
      return true;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Envoi du code impossible',
      );
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final retry = data['retry_after_seconds'];
          if (retry is int) {
            _retryAfterSeconds = retry;
          } else if (retry is num) {
            _retryAfterSeconds = retry.toInt();
          }
        }
      }
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> confirmRegister({
    required String email,
    required String code,
  }) async {
    _setBusy(true);
    _authMutationVersion++;
    _errorMessage = null;
    try {
      _user = await _repository.confirmRegister(
        email: email,
        code: code,
      );
      return true;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Verification impossible',
      );
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    _setBusy(true);
    _errorMessage = null;

    try {
      await _repository.requestPasswordReset(email: email);
      return true;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Reinitialisation impossible',
      );
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> completePasswordReset({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    _setBusy(true);
    _errorMessage = null;

    try {
      await _repository.completePasswordReset(
        token: token,
        password: password,
        confirmPassword: confirmPassword,
      );
      return true;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Reset mot de passe impossible',
      );
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> reloadCurrentUser() async {
    try {
      _user = await _repository.me();
      notifyListeners();
    } catch (_) {
      // Ignore volontairement pour eviter une deconnexion sauvage.
    }
  }

  void setUser(UserModel? user) {
    _authMutationVersion++;
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    _setBusy(true);
    _authMutationVersion++;
    try {
      await _repository.logout();
    } catch (_) {
      await _repository.clearLocalSession();
    } finally {
      _user = null;
      _setBusy(false);
    }
  }

  void _handleSessionExpired() {
    unawaited(_repository.clearLocalSession());
    _user = null;
    _errorMessage = 'Session expirée ou invalide (401).';
    _isBootstrapping = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  bool _isUnauthorized(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      return code == 401 || code == 403;
    }
    return false;
  }
}

