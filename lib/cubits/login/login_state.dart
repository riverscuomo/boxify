import 'package:boxify/app_core.dart';
import 'package:equatable/equatable.dart';

enum LoginStatus { initial, submitting, success, error }

class LoginState extends Equatable {
  final String email;
  final String password;
  final bool showPassword;
  final LoginStatus status;
  final Failure failure;
  
  // New field to control error display.
  final bool showValidation;

  bool get isFormValid => email.isNotEmpty && password.isNotEmpty;
  bool get isEmailValid => email.contains('@');
  bool get isPasswordValid => password.length >= 6;

  const LoginState({
    required this.email,
    required this.password,
    required this.showPassword,
    required this.status,
    required this.failure,
    required this.showValidation,
  });

  factory LoginState.initial() {
    return LoginState(
      email: "",
      password: '',
      showPassword: true,
      status: LoginStatus.initial,
      failure: Failure(),
      showValidation: false,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [email, password, showPassword, status, failure, showValidation];

  LoginState copyWith({
    String? email,
    String? password,
    bool? showPassword,
    LoginStatus? status,
    Failure? failure,
    bool? showValidation,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      showPassword: showPassword ?? this.showPassword,
      status: status ?? this.status,
      failure: failure ?? this.failure,
      showValidation: showValidation ?? this.showValidation,
    );
  }
}
