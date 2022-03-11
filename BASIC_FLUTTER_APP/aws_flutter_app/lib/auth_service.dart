import 'dart:async';

import 'package:amplify_core/amplify_core.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
//import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:aws_flutter_app/auth_credentials.dart';

// 1
enum AuthFlowStatus { login, signUp, verification, session }

// 2
class AuthState {
  final AuthFlowStatus authFlowStatus;

  AuthState({required this.authFlowStatus});
}

// 3
class AuthService {
  // 4
  final authStateController = StreamController<AuthState>();

  late AuthCredentials _credentials;

  // 5
  void showSignUp() {
    final state = AuthState(authFlowStatus: AuthFlowStatus.signUp);
    authStateController.add(state);
  }

  // 6
  void showLogin() {
    final state = AuthState(authFlowStatus: AuthFlowStatus.login);
    authStateController.add(state);
  }

  // 1
  // void loginWithCredentials(AuthCredentials credentials) {
  //   final state = AuthState(authFlowStatus: AuthFlowStatus.session);
  //   authStateController.add(state);
  // }
  // 1
  void loginWithCredentials(AuthCredentials credentials) async {
    try {
      // 2
      final result = await Amplify.Auth.signIn(
          username: credentials.username, password: credentials.password);

      // 3
      if (result.isSignedIn) {
        final state = AuthState(authFlowStatus: AuthFlowStatus.session);
        authStateController.add(state);
      } else {
        // 4
        print('User could not be signed in');
      }
    } on AmplifyException catch (authError) {
      print('Could not login - ${authError.message}');
    }
  }

  // 2
  Future<void> signUpWithCredentials(SignUpCredentials credentials) async {
    try {
      // 2
      //final userAttributes = {'email': credentials.email};
      Map<CognitoUserAttributeKey, String> userAttributes = {
        CognitoUserAttributeKey.email: credentials.email,
      };

      // 3
      final result = await Amplify.Auth.signUp(
          username: credentials.username,
          password: credentials.password,
          options: CognitoSignUpOptions(userAttributes: userAttributes));

      // 4
      if (result.isSignUpComplete) {
        if (result.nextStep.signUpStep == 'CONFIRM_SIGN_UP_STEP') {
          // continue to confirm sign up step
          // 5
          this._credentials = credentials;

          // 6
          final state = AuthState(authFlowStatus: AuthFlowStatus.verification);
          authStateController.add(state);
        }

        if (result.nextStep.signUpStep == 'DONE') {
          // complete sign up
          loginWithCredentials(credentials);
        }

      }
      else {
        print( result.isSignUpComplete);
      }
      // 7
    } on AmplifyException catch (authError) {
      print('Failed to sign up - ${authError.message}');
    }
    //final state = AuthState(authFlowStatus: AuthFlowStatus.verification);
    //authStateController.add(state);
  }

  // void verifyCode(String verificationCode) {
  //   final state = AuthState(authFlowStatus: AuthFlowStatus.session);
  //   authStateController.add(state);
  // }
  // 1
  void verifyCode(String verificationCode) async {
    try {
      // 2
      final result = await Amplify.Auth.confirmSignUp(
          username: _credentials.username, confirmationCode: verificationCode);

      // 3
      if (result.isSignUpComplete) {
        loginWithCredentials(_credentials);
      } else {
        // 4
        // Follow more steps
      }
    } on AmplifyException catch (authError) {
      print('Could not verify code - ${authError.message}');
    }
  }

  // void logOut() {
  //   final state = AuthState(authFlowStatus: AuthFlowStatus.login);
  //   authStateController.add(state);
  // }
  void logOut() async {
    try {
      // 1
      await Amplify.Auth.signOut();

      // 2
      showLogin();
    } on AmplifyException catch (authError) {
      print('Could not log out - ${authError.message}');
    }
  }

  void checkAuthStatus() async {
    try {
      await Amplify.Auth.fetchAuthSession();

      final state = AuthState(authFlowStatus: AuthFlowStatus.session);
      authStateController.add(state);
    } catch (_) {
      final state = AuthState(authFlowStatus: AuthFlowStatus.login);
      authStateController.add(state);
    }
  }
}
