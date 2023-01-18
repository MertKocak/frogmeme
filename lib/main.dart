import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frogmeme/service/admob_service.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const VideoApp());
}

/// Stateful widget to fetch and then display video content.
class VideoApp extends StatefulWidget {
  const VideoApp({Key? key}) : super(key: key);

  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  late VideoPlayerController _controller;
  dynamic score = 0;
  Color green = Color.fromARGB(255, 15, 143, 19);

  int _counter = 0;
  BannerAd? _banner;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  setScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("score", score);
  }

  getScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      score = prefs.getInt("score");
      if (score == null) {
        score = 0;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('asset/video/frogmeme.mp4')
      ..initialize().then((_) {
        setState(() {});
      });
    getScore();
    _createBannerAd();
    _createInterstitialAd();
    _createRewardedAd();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'frogmeme',
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            "Frog",
            style: TextStyle(fontSize: 36),
          ),
          elevation: 0,
          backgroundColor: green,
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 30,
            ),
            Text(
              "Score\n${score}",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: green),
            ),
            Expanded(child: SizedBox()),
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Container(
                        padding: EdgeInsets.all(52),
                        color: Colors.transparent,
                        child: InkWell(
                            onTap: () {
                              _controller.play();
                              if (_controller.value.isPlaying) {
                                null;
                              } else {
                                setState(() {
                                  score++;
                                });
                                frogOnPressed();
                                setScore();
                              }
                            },
                            child: Container(
                              padding:
                                  EdgeInsets.only(left: 5, top: 7, bottom: 7),
                              decoration: BoxDecoration(color: Colors.black),
                              child: VideoPlayer(_controller),
                            )),
                      ),
                    )
                  : Container(),
            ),
            Expanded(
              child: SizedBox(),
            ),
          ],
        ),
        bottomNavigationBar: _banner == null
            ? Container()
            : Container(
                margin: const EdgeInsets.only(),
                height: 52,
                child: AdWidget(ad: _banner!),
              ),
      ),
    );
  }

  void _createBannerAd() {
    _banner = BannerAd(
        size: AdSize.fullBanner,
        adUnitId: AdMobService.bannerAdUnitId!,
        listener: AdMobService.bannerListener,
        request: const AdRequest())
      ..load();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: AdMobService.interstitialUnitAdId!,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _interstitialAd = ad,
          onAdFailedToLoad: (LoadAdError error) => _interstitialAd = null,
        ));
  }

  void frogOnPressed() {
    _counter++;
    if (_counter > 0 && _counter % 10 == 0) {
      _showInterstitialAd();
    } else if (_counter > 0 && _counter % 62 == 0) {
      _showRewardedAd();
    }
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _createInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  void _createRewardedAd() {
    RewardedAd.load(
        adUnitId: AdMobService.rewardedAdUnitId!,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) => setState(() => _rewardedAd = ad),
          onAdFailedToLoad: (error) => setState(() => _rewardedAd = null),
        ));
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _createRewardedAd();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward of $reward');
        },
      );
      _rewardedAd = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
