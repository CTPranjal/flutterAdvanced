import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'local_notification.dart';
import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:firebase/local_notification.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage remoteMessage) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Got a message in the Background');
  print('message data: ${remoteMessage.data.containsKey('wzrk_acct_id')}');
  print('this is the value of remoteMessage.notification is ${remoteMessage.notification.toString()}');

  if (Platform.isAndroid) {
    print("yes we are android");
    if (remoteMessage.data.containsKey('wzrk_acct_id')) {
      //if (true) {
      /// CleverTap notification
      print("RemoteMessage clevertap in app: ${remoteMessage.data}");
      final dataPayload = jsonEncode(remoteMessage.data);
      CleverTapPlugin.createNotification(dataPayload);
    } else {
      /// Normal notification
      //_notificationService.showNotifications(remoteMessage);
    }
  }
  print("Handling a background message: ${remoteMessage.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  NotificationService().init();
  runApp(MyApp(state: ApplicationState()));
  CleverTapPlugin.setDebugLevel(3);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.state});
  final ApplicationState state;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState(){
    activateCleverTapFlutterPluginHandlers();
    super.initState();
  }
  void activateCleverTapFlutterPluginHandlers() {
    //Handler for receiving Push Clicked Payload in FG and BG state
    CleverTapPlugin().setCleverTapPushClickedPayloadReceivedHandler(pushClickedPayloadReceived);
  }
//For Push Notification Clicked Payload in FG and BG state
  void pushClickedPayloadReceived(Map<String, dynamic> map) {
    debugPrint("pushClickedPayloadReceived called");
    CleverTapPlugin.createNotification(map);
    print("pushClickedPayloadReceived called with notification payload: " + map.toString());
  }
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Firebase Cloud Messaging', state: widget.state),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.state});
  final ApplicationState state;
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CleverTapPlugin _clevertapPlugin;
  @override
  void initState() {
    super.initState();
    CleverTapPlugin.setDebugLevel(3);
    initPlatformState();
    // activateCleverTapFlutterPluginHandlers();
    CleverTapPlugin.createNotificationChannel(
        "P01", "Test Notification Flutter", "Flutter Test", 5, true);
  }

  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  // void activateCleverTapFlutterPluginHandlers() {
  //   _clevertapPlugin = CleverTapPlugin();
  //   //Handler for receiving Push Clicked Payload in FG and BG state
  //   _clevertapPlugin.setCleverTapPushClickedPayloadReceivedHandler(pushClickedPayloadReceived);
  // }
  // //For Push Notification Clicked Payload in FG and BG state
  // void pushClickedPayloadReceived(Map<String, dynamic> map) {
  //   debugPrint("pushClickedPayloadReceived called");
  //   CleverTapPlugin.createNotification(map);
  //   print("pushClickedPayloadReceived called with notification payload: " + map.toString());
  //
  //   // this.setState(() async {
  //   //   var data = jsonEncode(map);
  //   //   debugPrint("on Push Click Payload = $data");
  //   // });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListenableBuilder(
          listenable: widget.state,
          builder: (context, child) => Column(
            children: <Widget>[
              Visibility(
                visible: widget.state.messagingAllowed,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Click the "Send Notification " button below to receive a notification',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('FCM Token: ${widget.state.fcmToken}'),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.state.subscribeToPush('push'),
                      child: const Text('Send Notification'),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: !widget.state.messagingAllowed,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Thi quickstart requires notification permissions to be'
                            ' activated.',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.state.requestMessagingPermission(),
                      child: const Text('Request Notification Permission'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }
  late FirebaseMessaging firebaseMessaging;
  String _fcmToken = '';
  String get fcmToken => _fcmToken;
  bool _messagingAllowed = false;
  bool get messagingAllowed => _messagingAllowed;
  final NotificationService _notificationService = NotificationService();

  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseMessaging = FirebaseMessaging.instance;
    firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint(token);
      notifyListeners();
      // If necessary send token to application server.
      // Note: This callback is fired at each app startup and whenever a new
      // token is generated.
    });

    const vapidKey = '';
    firebaseMessaging.getToken(vapidKey: vapidKey).then((token) {
      if (token != null) {
        _fcmToken = token;
        print(token);
        debugPrint(token);
        notifyListeners();
      }
    });

    firebaseMessaging.getNotificationSettings().then((settings) {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _messagingAllowed = true;
        notifyListeners();
      }
    });

    FirebaseMessaging.onMessage.listen((remoteMessage) async {
      renderNotification(remoteMessage);
    });
  }

  Future<void> requestMessagingPermission() async {
    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _messagingAllowed = true;
      notifyListeners();
    }

    debugPrint('Users permission status: ${settings.authorizationStatus}');
  }
  Future<void> renderNotification(RemoteMessage remoteMessage) async{
    print('Got a message in the foreground');
    print('message data: ${remoteMessage.data.containsKey('wzrk_acct_id')}');
    print('this is the value of remoteMessage.notification is ${remoteMessage.notification.toString()}');

    if (Platform.isAndroid) {
      print("This is an android device");
      if (remoteMessage.data.containsKey('wzrk_acct_id')) {
        //if (true) {
        /// CleverTap notification
        print("RemoteMessage from clevertap: ${remoteMessage.data}");
        final dataPayload = jsonEncode(remoteMessage.data);
        CleverTapPlugin.createNotification(dataPayload);
      } else {
        /// Normal notification
        print('This is a notification from Firebase Console');
        _notificationService.showNotifications(remoteMessage);
      }
    }
  }

  Future<void> subscribeToPush(String topic) async {
    // await firebaseMessaging.subscribeToPush(topic);
    CleverTapPlugin.recordEvent("flutterTest",{});

  }
}