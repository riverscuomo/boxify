import 'package:boxify/app_core.dart';
import 'package:equatable/equatable.dart';

enum LoginStatus { initial, submitting, success, error }

class LoginState extends Equatable {
  final String email;
  final String password;
  final bool showPassword;
  final LoginStatus status;
  final Failure failure;  

  bool get isFormValid => email.isNotEmpty && password.isNotEmpty;

  const LoginState({
    required this.email,
    required this.password,
    required this.showPassword,
    required this.status,
    required this.failure,
  });

  factory LoginState.initial() {
    return LoginState(
      email: "",
      password: '',
      showPassword: true,
      status: LoginStatus.initial,
      failure: Failure(),
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [email, password, showPassword, status, failure];

  LoginState copyWith({
    String? email,
    String? password,
    bool? showPassword,
    LoginStatus? status,
    Failure? failure,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      showPassword: showPassword ?? this.showPassword,
      status: status ?? this.status,
      failure: failure ?? this.failure,
    );
  }
}
