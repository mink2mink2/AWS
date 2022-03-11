import 'package:amplify_analytics_pinpoint/amplify_analytics_pinpoint.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

import 'package:aws_flutter_app/auth_service.dart';
import 'package:aws_flutter_app/camera_flow.dart';
import 'package:aws_flutter_app/login_page.dart';
import 'package:aws_flutter_app/sign_up_page.dart';
import 'package:aws_flutter_app/verification_page.dart';
import 'package:flutter/material.dart';

import 'amplifyconfiguration.dart';

void main() {
  runApp(MyApp());
}

// 1
class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _amplify = Amplify;
  late AmplifyAuthCognito auth;
  late AmplifyStorageS3 storageS3;
  late AmplifyAnalyticsPinpoint analytics;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _configureAmplify();
    //_authService.showLogin();
    _authService.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Gallery App',
      theme: ThemeData(visualDensity: VisualDensity.adaptivePlatformDensity),
      // 2
      home: StreamBuilder<AuthState>(
          stream: _authService.authStateController.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Navigator(
                pages: [
                  // 4
                  // Show Login Page
                  if (snapshot.data?.authFlowStatus == AuthFlowStatus.login)
                    MaterialPage(
                        child: LoginPage(
                      didProvideCredentials: _authService.loginWithCredentials,
                      shouldShowSignUp: _authService.showSignUp,
                    )),

                  // 5
                  // Show Sign Up Page
                  if (snapshot.data?.authFlowStatus == AuthFlowStatus.signUp)
                    MaterialPage(
                        child: SignUpPage(
                      didProvideCredentials: _authService.signUpWithCredentials,
                      shouldShowLogin: _authService.showLogin,
                    )),

                  // Show Verification Code Page
                  if (snapshot.data?.authFlowStatus ==
                      AuthFlowStatus.verification)
                    MaterialPage(
                        child: VerificationPage(
                            didProvideVerificationCode:
                                _authService.verifyCode)),
                  // Show Camera Flow
                  if (snapshot.data?.authFlowStatus == AuthFlowStatus.session)
                    MaterialPage(
                        child: CameraFlow(shouldLogOut: _authService.logOut))
                ],
                onPopPage: (route, result) => route.didPop(result),
              );
            } else {
              // 6
              return Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }

  void _configureAmplify() async {
    auth = AmplifyAuthCognito();
    storageS3 = AmplifyStorageS3();
    analytics = AmplifyAnalyticsPinpoint();
    //await _amplify.addPlugin(auth);
    //await _amplify.addPlugin(storageS3);
    await _amplify.addPlugins([auth, storageS3, analytics]);
    try {
      await _amplify.configure(amplifyconfig);
      print('Successfully configured Amplify 🎉');
    } catch (e) {
      print('Could not configure Amplify ☠️');
    }
  }
}
