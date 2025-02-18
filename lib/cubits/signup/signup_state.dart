part of 'signup_cubit.dart';

enum SignupStatus { initial, submitting, success, error }

class SignupState extends Equatable {
  final String email;
  final String password;
  final bool usernameIsValid;
  final SignupStatus status;
  final Failure failure;
  
  // New field:
  final bool showValidation;

  bool get isFormValid => email.isNotEmpty && password.isNotEmpty;
  bool get isEmailValid => email.contains('@');
  bool get isPasswordValid => password.length >= 6;

  const SignupState({
    required this.email,
    required this.password,
    required this.usernameIsValid,
    required this.status,
    required this.failure,
    required this.showValidation,
  });

  factory SignupState.initial() {
    return const SignupState(
      email: '',
      password: '',
      usernameIsValid: false,
      status: SignupStatus.initial,
      failure: Failure(),
      showValidation: false,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [
        email, password, usernameIsValid, status, failure, showValidation
      ];

  SignupState copyWith({
    String? email,
    String? password,
    bool? usernameIsValid,
    SignupStatus? status,
    Failure? failure,
    bool? showValidation,
  }) {
    return SignupState(
      email: email ?? this.email,
      password: password ?? this.password,
      usernameIsValid: usernameIsValid ?? this.usernameIsValid,
      status: status ?? this.status,
      failure: failure ?? this.failure,
      showValidation: showValidation ?? this.showValidation,
    );
  }
}
