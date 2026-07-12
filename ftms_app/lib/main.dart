
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io' show Platform;
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/network/dio_client.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive
  await Hive.initFlutter();

  // Pre-load auth token so media widgets don't get 401 on first render
  const _storage = FlutterSecureStorage();
  DioClient.authToken = await _storage.read(key: AppConstants.tokenKey);

  // System UI (Android)
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F0F1A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(AuthRepository())
            ..add(CheckAuthStatus()),
        ),
      ],
      child: const FTMSApp(),
    ),
  );
}
