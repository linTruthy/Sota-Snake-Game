import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:easy_ads_flutter/easy_ads_flutter.dart';
import 'package:sota_snake_game/app.dart';

import 'firebase_options.dart';
import 'services/ad_id_manager.dart';
import 'services/play_games_service.dart';
import 'services/score_manager.dart';

const IAdIdManager adIdManager = AdIdManagerX();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await PlayGamesService().initialize();
  await EasyAds.instance.initialize(
    isShowAppOpenOnAppStateChange: false,
    adIdManager,
    unityTestMode: false,
    fbTestMode: false,
    adMobAdRequest: const AdRequest(),
    admobConfiguration: RequestConfiguration(
        testDeviceIds: ["73D83286C35132200529A93C555F5FD6"]),
    fbTestingId: 'd3b083f0-2987-4d05-a402-aba2011070f4',
    fbiOSAdvertiserTrackingEnabled: true,
  );

  await ScoreManager().initialize();
  runApp(const MyApp());
}
