import 'package:boxify/models/color_adaptor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import 'package:boxify/helpers/flutter_device_type.dart';
import 'package:flutter/foundation.dart';
import 'package:boxify/app_core.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:universal_html/html.dart' as html;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:easy_logger/easy_logger.dart';
import 'package:boxify/helpers/url_strategy_web_stub.dart'
    if (dart.library.html) 'package:boxify/helpers/url_strategy_web.dart'
    if (dart.library.io) 'package:boxify/helpers/url_strategy_web_stub.dart'
    as web;

/// Core is a singleton that provides a central repository of app-wide
/// utilities and configuration. It grants convenient access to device
/// details, screen dimensions, app settings, and sets up essential services
/// like Firebase. Core ensures app-wide consistency by offering static
/// properties and methods to be used across the application.
///
/// Example usage for accessing screen width:
/// double width = Core.screenWidth;
class Core {
  static get localhost => isDevice
      ? 'http://192.168.2.111'
      : (isAndroid ? 'http://10.0.2.2' : 'http://localhost');

  static bool? _isTablet;
  static get isTablet => (_isTablet ??= !kIsWeb &&
      Device.get().isTablet); // will crash on web without kIsWeb check
  static get isIOS => !kIsWeb && Platform.isIOS;
  static get isAndroid => !kIsWeb && Platform.isAndroid;
  static get isOldAndroid =>
      !kIsWeb && Platform.isAndroid && systemVersion.floor() < 21;
  static get isAndroid11 =>
      !kIsWeb && Platform.isAndroid && systemVersion.floor() == 30;
  static get isNewAndroid =>
      !kIsWeb && Platform.isAndroid && systemVersion.floor() >= 30;
  static get debugMode => kDebugMode;
  static bool isSamsung = false;
  static bool isDevice = true;
  static get platform {
    if (Core.isAndroid) return "android";
    if (Core.isIOS) return "ios";
    return "unknown";
  }

  static Locale? deviceLocale;
  static bool is24HoursFormat = false;
  static double systemVersion = 0;
  static String tempPath = '';
  static String storagePath = '';
  static String dataPath = '';
  static late String? librarySectionHeader;
  static late BaseApp app;
  static late BaseStyle appStyle;
  static late BaseColor appColor;
  static late BaseUI appUI;

  static double scaleFactor = 1;

  static String appVersion = '';

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  }

  /// Initializes the common dependencies and resources across both apps.
  ///
  /// `init` is a helper function used to setup key app dependencies and configurations. It sets up the base app, style, color, and user interface using the provided parameters or default values. If Firebase options are provided, Firebase is initialized, Crashlytics and Analytics are set up, and unhandled errors are configured to be caught and reported. The method further initializes the audio provider and local language settings, and collects device data for mobile platforms.
  ///
  /// Parameters:
  /// - `appName`: Name of the application to initialize.
  /// - `baseApp`: A basic application configuration. If not provided, a default one is created.
  /// - `baseStyle`: A base style configuration. If not supplied, a default style is applied.
  /// - `baseColor`: A base color configuration. Defaults to a standard set if not provided.
  /// - `baseUI`: A base User Interface configuration. Defaults to a standard UI if not provided.
  /// - `firebaseOptions`: The options used to initialize Firebase.
  ///
  /// Returns:
  /// - `Future<void>`: Once the application has been initialized successfully, a complete future is returned.
  static init({
    required String appName,
    FirebaseOptions? firebaseOptions,
    dynamic baseApp,
    dynamic baseStyle,
    dynamic baseColor,
    dynamic baseUI,
  }) async {
    app = baseApp ?? BaseApp();
    appStyle = baseStyle ?? BaseStyle();
    appColor = baseColor ?? BaseColor();
    appUI = baseUI ?? BaseUI();

    // Initialize ConnectivityManager
    await ConnectivityManager.instance.init();

    /// You shouldprobably not do this. (show the route in the url bar even when pushed)
    /// https://pub.dev/documentation/go_router/latest/go_router/GoRouter/optionURLReflectsImperativeAPIs.html
    GoRouter.optionURLReflectsImperativeAPIs = true;
    print('initializing core');
    if (kIsWeb) {
      if (firebaseOptions == null) {
        throw Exception('Firebase options must be provided for web apps');
      }

      logger.i('initializing firebase on web');

      await Firebase.initializeApp(options: firebaseOptions);

      // crashes on android. it's meant for web. So you can mouse click to access context menus
      html.window.document.onContextMenu.listen((evt) => evt.preventDefault());

      // Initialize Hive for web app
      Hive.init(appName);

      // logger.d('here we go');
      web.setPathUrlStrategy();
    } else {
      print('initializing firebase on mobile');
      await Firebase.initializeApp();
      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError; // not on web

      // Initialize Hive for mobile apps
      print('initializing hive for mobile');
      await Hive.initFlutter();

      // Register the adapters
      Hive.registerAdapter(TrackAdapter()); // Generated by build_runner
      Hive.registerAdapter(ColorAdapter());

      print('getting instance of firebase messaging');
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      print('requesting permission for messaging');
      // Request permission for iOS (if applicable)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    }

    EquatableConfig.stringify = kDebugMode;

    print('initializing just audio background');
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.rivers.$appName.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );

    await EasyLocalization.ensureInitialized();
    EasyLocalization.logger.enableLevels = [
      LevelMessages.error,
      LevelMessages.info
    ]; // Hide all the missing key warnings
    print('easy localization initialized');
    logger.f('yourLibrary'.localized());

    // logger.i('iCore.init done');

    deviceLocale = await Devicelocale.currentAsLocale;
    logger.i('device locale: $deviceLocale');

    IOSDeepLinkService.instance; // WORK IN PROGRESS

    await NotificationService.initialize();

    await app.init();
    logger.i('iCore.app.init done');
  }

  static postInit() async {
    logger.i('core postInit');
    await app.postInit();
  }
}

// extension StateEx on State {
//   Color get primaryColor => Core.appColor.primary;
//   Color get backgroundColor => Core.appColor.background;
//   Color get actionButtonColor => Core.appColor.primary;

//   double get screenWidth => MediaQuery.of(context).size.width;
//   double get screenHeight => MediaQuery.of(context).size.height;
//   bool get isPortrait => screenWidth < screenHeight;
//   EdgeInsets get viewPadding => MediaQuery.of(context).viewPadding;
//   EdgeInsets get rootPadding =>
//       MediaQuery.of(Core.app.root(context) ?? context).viewPadding;
//   EdgeInsets get borderPadding => appUI.borderPadding;
//   double get buttonHeight => 44.0;
//   double get buttonBorderRadius => 6.0;

//   get buttonBorder {
//     return RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(buttonBorderRadius),
//     );
//   }

//   get backButton => Material(
//       color: Core.appColor.navBar,
//       child: BackButton(color: Core.appColor.primary));
//   // Widget get closeButton =>
//   //     CircularIconButton(Icons.cancel, onPressed: () => popFromRoot());
//   // get hasConnection => Reachability().hasConnection;
//   modalScrollController(BuildContext context) =>
//       ModalScrollController.of(context);

//   double get textScaleFactor =>
//       MediaQuery.maybeOf(context)?.textScaleFactor ?? 1;
//   maxScaleFactor(double val) => min(textScaleFactor, val);

//   // BaseApp get app => Core.app;
//   // BaseStyle get appStyle => Core.appStyle;
//   // BaseColor get appColor => Core.appColor;
//   // BaseUI get appUI => Core.appUI;

//   refreshView({Duration? delay}) {
//     if (delay != null) {
//       Future.delayed(delay, () => setState(() {}));
//     } else {
//       setState(() {});
//     }
//   }

//   setAppLanguage(Language language) {
//     app.setLanguage(language.code, save: true);
//     context.setLocale(language.locale);
//   }

//   resetAppLanguage() {
//     logger.i('deviceLocale: ${context.deviceLocale.toString()}');
//     app.setLanguage(context.deviceLocale.toString());
//     context.setLocale(app.language.locale);
//   }

//   // showView(Widget child,
//   //     {String? title,
//   //     bool replace = false,
//   //     bool animated = true,
//   //     bool root = false}) {
//   //   var route = animated || !replace
//   //       ? CupertinoPageRoute(builder: (context) => child)
//   //       : null;
//   //   if (replace) {
//   //     Navigator.of(context)
//   //         .pushReplacement(animated ? route! : ReplacementRoute(widget: child));
//   //   } else {
//   //     Navigator.of(context, rootNavigator: root).push(route!);
//   //   }
//   // }

//   // pushView(Widget view) => showView(view);
//   // replaceView(Widget view, {bool animated = false, Duration? delay}) =>
//   //     delay != null
//   //         ? Future.delayed(
//   //             delay, () => showView(view, replace: true, animated: animated))
//   //         : showView(view, replace: true, animated: animated);

//   // showSheet(Widget widget) {
//   //   Scaffold.of(context)
//   //       .showBottomSheet<void>((BuildContext context) => widget);
//   // }

//   // popFromRoot() {
//   //   try {
//   //     Navigator.of(context, rootNavigator: true).pop();
//   //   } catch (ex) {
//   //     logger.i('pop error: $ex');
//   //     var _context =
//   //         AppRoot.navKey.currentState?.context ?? app.rootContext ?? null;
//   //     if (_context != null) {
//   //       Navigator.of(_context, rootNavigator: true).pop();
//   //     }
//   //   }
//   // }

//   maybePopFromRoot() => Navigator.of(context, rootNavigator: true).maybePop();

//   loadingIndicator({Color? color}) => LoadingIndicator(color: color);

//   dismissKeyboard() {
//     FocusScopeNode currentFocus = FocusScope.of(context);
//     if (!currentFocus.hasPrimaryFocus) {
//       currentFocus.unfocus();
//     }
//   }

//   errorText(error, {Function? retry}) {
//     var message = '';
//     try {
//       message = error.toString();
//     } catch (ex) {
//       message = error;
//     }
//     return CenteredText(message);
//   }
// }

extension StatelessExt on StatelessWidget {
  BaseApp get app => Core.app;
  BaseStyle get appStyle => Core.appStyle;
  BaseColor get appColor => Core.appColor;
  BaseUI get appUI => Core.appUI;

  // showView(BuildContext context, Widget view,
  //     {String? title, bool replace = false}) {
  //   if (replace) {
  //     Navigator.of(context).pushReplacement(ReplacementRoute(widget: view));
  //   } else {
  //     Navigator.push(context, CupertinoPageRoute(builder: (context) => view));
  //   }
  // }

  // replaceView(BuildContext context, Widget view, {Duration? delay}) =>
  //     delay != null
  //         ? Future.delayed(delay, () => showView(context, view, replace: true))
  //         : showView(context, view, replace: true);
}

/// This extension adds localization functionality to [String] using the
/// EasyLocalization package. It provides methods to translate and localize
/// strings based on the language selected by the user. In the main app, it is for
/// the approximately 600 app-related translations such as 'Library', 'Settings', 'Home', etc. and is
/// not to be confused with the media-related translations fetched from the Portal server
/// and managed by the [LocalizationManager] class.
///
/// Note: fallback English translations are required for all the keys in the language .json files,
/// otherwise the method will return the key itself, which is not ideal.
///
/// By using the methods provided in this extension, we can translate
/// and localize strings in our apps based on the language
/// selected by the user.
extension StringLocalization on String {
  /// Returns the translated version of the string using the available
  /// translations from the EasyLocalization package.
  ///
  /// This method is an alias for `tr()` method from the package.
  /// When a translation for the given string is not available, it returns the original string.
  /// This ensures that the users still see some text, even if it is not in their preferred language.
  ///
  /// Note: this method depends on the language .json file having an English translation
  /// for all the keys without a translation in the current language. If a key is missing
  /// the method will return the key itself, which is not ideal.
  String localized({Map<String, String>? namedArgs}) =>
      this.tr(namedArgs: namedArgs);

  /// Returns the translated version of the string if it exists; otherwise,
  /// returns null.
  ///
  /// This method checks if the translated version of the string is different
  /// from the original string. If it's different, it returns the translated
  /// version; otherwise, returns null.
  String? localizedOrNull() {
    var val = this.tr();
    return val != this ? val : null;
  }

  /// Returns the translated version of the string using first the LocalizationManager
  /// (with the translations fetched from the portal) and, if that fails,
  /// the EasyLocalization package which contains the hardcoded translation bundled with
  /// the app assets.
  ///
  /// [fallback] (optional, default: true): If set to true, the method returns
  /// the translated version using the EasyLocalization package if the translation
  /// is not found in LocalizationManager.
  ///
  /// [namedArgs] (optional): A map of named arguments to be used in the translation.
  /// Arguments can be used in the translation string by enclosing them in curly braces.
  /// Example: 'Hello {name}'.translate(namedArgs: {'name': 'Thomas'}) will return 'Hello Thomas'.
  String translate({bool fallback = true, Map<String, String>? namedArgs}) =>
      localized(namedArgs: namedArgs);

  // // Try translating the string using LocalizationManager
  // LocalizationManager.translate(this)
  // // If translation is not found in LocalizationManager and fallback is true,
  // // use the translated version from EasyLocalization; otherwise, use the original string.
  // ??
  // (fallback ? localized() : this);
}

// void loglogger.i(Object o) {
//   logger.i(o);
//   Core.app.logEvent('log', message: o.toString());
// }

// void logError(Object o) {
//   if (kDebugMode) logger.io);
//   Core.app.logError("$o");
// }

// extension IntAltExt on int {
//   double tablet(int val) => (Core.app.isSplitView ? val : this).toDouble();
// }

// extension DoubleAltExt on double {
//   tablet(double val) => Core.app.isSplitView ? val : this;
// }

// extension ContextExt on BuildContext {
//   MaterialLocalizations get localization {
//     return MaterialLocalizations.of(this);
//   }

//   maxScaleFactor(double value) =>
//       min(MediaQuery.of(this).textScaleFactor, value);

//   bool get RTL => Directionality.of(this) == ui.TextDirection.rtl;
// }

// class ReplacementRoute extends PageRouteBuilder {
//   final Widget widget;
//   ReplacementRoute({required this.widget})
//       : super(pageBuilder: (context, a1, a2) {
//           return widget;
//         });
// }

// extension FunctionExt on Function {
//   delayed({int? seconds, int? mseconds}) {
//     var dur = Duration(
//         seconds: seconds ?? (mseconds == null ? 1 : 0),
//         milliseconds: mseconds ?? 0);
//     Future.delayed(dur, () => this());
//   }
// }

// extension ListUtils on List {
//   List<dynamic> flattenObjectList(Function getSublistField) {
//     List thisList = this;

//     for (var i = 0; i < thisList.length; i++) {
//       List<dynamic>? sublist = getSublistField(thisList[i]);
//       if (sublist != null && sublist.isNotEmpty) {
//         thisList.insertAll(i + 1, sublist);
//         i += sublist.length;
//       }
//     }

//     return thisList;
//   }

//   String joinLast([String separator = "", String lastSeparator = ""]) {
//     List thisList = this;
//     var listCopy = thisList.toList();
//     var lastItem = listCopy.removeLast();
//     listCopy = listCopy.isNotEmpty ? [listCopy.join(separator)] : [];
//     listCopy.add(lastItem);
//     return listCopy.join(lastSeparator);
//   }
// }

// extension FlutterErrorDetailsExt on FlutterErrorDetails {
//   get skipReporting {
//     if (Core.debugMode) return true;
//     var mesg = exception.toString().toLowerCase();
//     return mesg.contains('socketexception') ||
//         mesg.contains('connection') ||
//         mesg.contains('http');
//   }
// }
