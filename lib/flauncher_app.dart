/*
 * FFFusion
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flauncher/actions.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/unsplash_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database.dart';
import 'fffusion.dart';
import 'flauncher_channel.dart';

class FLauncherApp extends StatelessWidget {
  final SharedPreferences _sharedPreferences;
  final FirebaseCrashlytics _firebaseCrashlytics;
  final FirebaseAnalytics _firebaseAnalytics;
  final ImagePicker _imagePicker;
  final FLauncherChannel _fLauncherChannel;
  final FLauncherDatabase _fLauncherDatabase;
  final UnsplashService _unsplashService;
  final RemoteConfig _remoteConfig;

  // Modern Material 3 color scheme inspired by Fusion OS
  static const Color _primaryColor = Color(0xFF667EEA);
  static const Color _secondaryColor = Color(0xFF764BA2);
  static const Color _tertiaryColor = Color(0xFF00D9FF);

  FLauncherApp(
    this._sharedPreferences,
    this._firebaseCrashlytics,
    this._firebaseAnalytics,
    this._imagePicker,
    this._fLauncherChannel,
    this._fLauncherDatabase,
    this._unsplashService,
    this._remoteConfig,
  );

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SettingsService(
              _sharedPreferences,
              _firebaseCrashlytics,
              _firebaseAnalytics,
              _remoteConfig,
            ),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => AppsService(_fLauncherChannel, _fLauncherDatabase),
          ),
          ChangeNotifierProxyProvider<SettingsService, WallpaperService>(
            create: (_) => WallpaperService(
              _imagePicker,
              _fLauncherChannel,
              _unsplashService,
            ),
            update: (_, settingsService, wallpaperService) =>
                wallpaperService!..settingsService = settingsService,
          )
        ],
        child: MaterialApp(
          shortcuts: {
            ...WidgetsApp.defaultShortcuts,
            SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.gameButtonB):
                PrioritizedIntents(
              orderedIntents: [
                DismissIntent(),
                BackIntent(),
              ],
            ),
          },
          actions: {
            ...WidgetsApp.defaultActions,
            DirectionalFocusIntent: SoundFeedbackDirectionalFocusAction(),
          },
          title: 'FFFusion',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.dark(
              primary: _primaryColor,
              secondary: _secondaryColor,
              tertiary: _tertiaryColor,
              background: Color(0xFF0F0E17),
              surface: Color(0xFF1A192D),
              error: Color(0xFFCF6679),
            ),
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: true,
            ),
            textTheme: TextTheme(
              displayLarge: TextStyle(
                fontSize: 57,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              displayMedium: TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              displaySmall: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              headlineLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              headlineMedium: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              headlineSmall: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              titleLarge: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              titleSmall: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
              bodySmall: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white60,
              ),
              labelLarge: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              labelMedium: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              labelSmall: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            iconTheme: IconThemeData(
              color: Colors.white,
              size: 24,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF1A192D).withOpacity(0.8),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _primaryColor,
                  width: 2,
                ),
              ),
              labelStyle: TextStyle(
                color: Colors.white70,
              ),
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: _primaryColor,
              selectionColor: _primaryColor.withOpacity(0.3),
              selectionHandleColor: _primaryColor,
            ),
            buttonTheme: ButtonThemeData(
              buttonColor: _primaryColor,
              textTheme: ButtonTextTheme.primary,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(
                  color: _primaryColor,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            cardTheme: CardTheme(
              color: Color(0xFF1A192D),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            dialogTheme: DialogTheme(
              backgroundColor: Color(0xFF1A192D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 24,
            ),
          ),
          home: Builder(
            builder: (context) => WillPopScope(
              onWillPop: () => shouldPopScope(context),
              child: Actions(
                actions: {
                  BackIntent: BackAction(
                    context,
                    systemNavigator: true,
                  )
                },
                child: FFFusion(),
              ),
            ),
          ),
        ),
      );
}
