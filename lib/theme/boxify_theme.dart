import 'package:flutter/material.dart';
import 'package:boxify/app_core.dart';

/// Refer to the values that are set in each app's app.dart file, so they can have their colors and styles
/// rather than using actual [Color]s and [TextStyle]s here.
class BoxifyTheme {
  static ThemeData buildTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Core.appColor.scaffoldBackgroundColor,
      primaryColor: Core.appColor.primary,
      textTheme: ThemeData.dark().textTheme.copyWith(
            bodyLarge: TextStyle(color: Core.appColor.text),
            bodyMedium: TextStyle(color: Core.appColor.text),
            bodySmall: TextStyle(color: Core.appColor.text),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Core.appColor.text,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Core.appColor.text,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Core.appColor.text,
        ),
      ),
      iconTheme: IconThemeData(
        color: Core.appColor.icon,
      ),
      appBarTheme: AppBarTheme(
        iconTheme: IconThemeData(
          color: Core.appColor.icon
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        actionTextColor: Core.appColor.text,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Core.appColor.icon,
        selectionColor: Core.appColor.text.withOpacity(0.5),
        selectionHandleColor: Core.appColor.icon,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Core.appColor.primary
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Core.appColor.focusBorder, 
            width: 2.0
          ),
        ),
        labelStyle: TextStyle(
          color: Core.appColor.hintText
        ), 
        hintStyle: TextStyle(
          color: Core.appColor.hintText
        ),
      ),
    );
  }
}
