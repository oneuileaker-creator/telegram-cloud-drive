
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoginRequested extends AuthEvent {
  final String email, password;
  LoginRequested(this.email, this.password);
  @override List<Object?> get props => [email, password];
}
class RegisterRequested extends AuthEvent {
  final String email, username, password;
  RegisterRequested(this.email, this.username, this.password);
}
class LogoutRequested extends AuthEvent {}
class CheckAuthStatus extends AuthEvent {}
class TelegramConnectRequested extends AuthEvent {
  final int apiId;
  final String apiHash, phoneNumber;
  TelegramConnectRequested(this.apiId, this.apiHash, this.phoneNumber);
}
class TelegramVerifyRequested extends AuthEvent {
  final String phoneNumber, code, phoneCodeHash;
  TelegramVerifyRequested(this.phoneNumber, this.code, this.phoneCodeHash);
}

// States
abstract class AuthState extends Equatable {
  @override List<Object?> get props => [];
}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override List<Object?> get props => [message];
}
class TelegramCodeSent extends AuthState {
  final String phoneCodeHash;
  TelegramCodeSent(this.phoneCodeHash);
}
class TelegramConnected extends AuthState {}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {

    on<CheckAuthStatus>((event, emit) async {
      final token = await _repo.getToken();
      if (token != null) {
        try {
          final user = await _repo.getMe();
          emit(AuthAuthenticated(user));
        } catch (_) {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _repo.login(
          email: event.email,
          password: event.password,
        );
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _repo.register(
          email: event.email,
          username: event.username,
          password: event.password,
        );
        final user = await _repo.getMe();
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<LogoutRequested>((event, emit) async {
      await _repo.logout();
      emit(AuthUnauthenticated());
    });

    on<TelegramConnectRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final result = await _repo.telegramConnect(
          apiId: event.apiId,
          apiHash: event.apiHash,
          phoneNumber: event.phoneNumber,
        );
        emit(TelegramCodeSent(result['phone_code_hash']));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<TelegramVerifyRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _repo.telegramVerify(
          phoneNumber: event.phoneNumber,
          code: event.code,
          phoneCodeHash: event.phoneCodeHash,
        );
        final user = await _repo.getMe();
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}
