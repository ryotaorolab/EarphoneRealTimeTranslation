import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  String LatestText = ""; // 前回の会話ログを削除したテキスト内容
  String ResultTranslation = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// これは、アプリごとに 1 回だけ発生する必要があります
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }
  /// 音声認識セッションを開始するたびに(聞き取りボタンを押すたびに)
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      ///指定した秒ごとに読み上げる処理を行う
      Timer.periodic(Duration(seconds: 5), (timer) async {
        // 非同期処理で関数を呼び出す
        if (TapSwitch == false) { // 長押し聞き取りボタンが押されていなければ
          await _speechToText.listen(onResult: _onSpeechResult);
          readaloudText();
        }
      });
    });
  }
  String SpeakLog = ""; //　今までの会話の内容を記録
  // 指定された時間ごとに実行される。
  Future readaloudText() async {
    // 前回の会話内容を削除する
    LogClean();
    // 読み上げ処理と認識文と翻訳文の初期化
    // 翻訳処理を行う
    Text_Translation(_lastWords);
    //読み上げを行います。
    ReadSpeaktoText();
    // ログを記録する
    SpeakLog = _lastWords;
    translation = "";
    _lastWords = "";
    ResultTranslation = '';
  }

  /// アクティブな音声認識セッションを手動で停止します
  /// 各プラットフォームが適用するタイムアウトもあり、SpeechToText プラグインはリッスン
  /// メソッドでのタイムアウトの設定をサポートしていることに注意してください。
  void _stopListening() async {
    await _speechToText.stop();
    SpeakLog = "";
    setState(() {});
  }

  /// これは、プラットフォームが認識した単語を返すときにSpeechToTextプラグインが呼び出すコールバックです
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  /// 読み上げ処理を行う
  void ReadSpeaktoText() {
    //読み上げを行います。
    _speak(language: "en-US", speakText: translation);
  }
  /// ログから会話メッセの前回の内容を削除する
  void LogClean() {
    //ログの文字数を調べます
    int SpeakLogLength = SpeakLog.length;
    //ログと重複する最初の文章を削除します。
    LatestText = _lastWords.substring(SpeakLogLength, _lastWords.length);
  }

  var translation = "";
  bool LogSwitch = false; // 翻訳完了の有無

  /// 翻訳をしている部分
  // 指定された時間ごとに実行される。(読み上げ時)
  Text_Translation(String lastwords) async {
    final translator = GoogleTranslator();
    translation = (await translator.translate(LatestText, from: 'ja', to: 'en')).text;
    // 翻訳処理を終えたことを知らせる
    LogSwitch = true;
  }
  
  FlutterTts flutterTts = FlutterTts();

  /// 読み上げ機能の部分
  void _speak({required String language, required String speakText}) async {
    if (speakText.isEmpty) {
      return;
    }
    // 読み上げる言語を設定（英語: en-US, 日本語: ja-JP）
    await flutterTts.setLanguage(language);
    // 読み上げる速度を設定（0.0〜1.0）
    await flutterTts.setSpeechRate(0.5);
    // speakTextを読み上げ
    await flutterTts.speak(speakText);

    // iOSのみ必要な部分
    //共有インスタンスのプラットフォーム固有のメソッドを呼び出す
    await flutterTts.setSharedInstance(true);
    // これは、オーディオカテゴリを設定するためのプラットフォーム固有のメソッドを呼び出します。
    await flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.ambient,
        [
          // Bluetoothハンズフリー機器の有無を決定するオプションです。
          // 利用可能な入力経路として表示される。
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          // オーディオをストリーミングできるかどうかを決定するオプション
          // このセッションから、A2DP（Advanced Audio Distribution Profile）をサポートするBluetooth機器に
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          // このセッションのオーディオをオーディオとミックスするかどうかを示すオプションです。
          // 他のオーディオアプリのアクティブなセッションから 。
          IosTextToSpeechAudioCategoryOptions.mixWithOthers
        ],
        // [Future]オーディオカテゴリを設定するためのプラットフォーム固有のメソッドを呼び出します。
        // IosTextToSpeechAudioMode.voicePrompt
    );
  }

  // ボタン長押しで聞き取りモードのときのボタンから離したした時の処理
  void ButtonOnTapUP() {
    setState(() {
      PushTranslation = "長押しで音声認識(手動モード)";
    });
    // // ボタン押していないときに呼ばれる
    TapSwitch = false;
    //　音声認識を止めます
    _speechToText.stop();
    // 前回の会話内容を削除する
    LogClean();
    // 読み上げ処理と認識文と翻訳文の初期化
    // 翻訳処理を行う
    Text_Translation(_lastWords);
    //読み上げを行います。
    ReadSpeaktoText();
    // ログを記録する
    SpeakLog = _lastWords;
    translation = "";
    _lastWords = "";
    ResultTranslation = '';
  }

  // 翻訳スイッチの状態
  bool TapSwitch = false;
  String PushTranslation = "長押しで音声認識(手動モード)";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                '認識された言葉',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column( // Columnウィジェットを使ってTextウィジェットを縦に並べる
                  children: [
                    Text(
                      _speechToText.isListening
                          ? '$LatestText'
                          : _speechEnabled
                          ? 'マイクをタップして聞き取りを開始します...'
                          : 'スピーチは利用できません',
                    ),
                    Text(
                      translation,
                    ),
                    Text(
                        "文字数Log " + SpeakLog.length.toString(),
                    ),
                    Text(
                      "Log " + SpeakLog,
                    )
                  ],
                ),
              ),
            ),
        GestureDetector(

          onTapDown: (_) {
            setState(() {
              PushTranslation = "音声を聞き取りしています。";
            });
            // ボタン押している時に呼ばれる
            TapSwitch = true;
            // 音声認識を開始する
            _speechToText.listen(onResult: _onSpeechResult);
          },
          onTapUp: (_) {
            ButtonOnTapUP();
          },
          onTapCancel: () {
            ButtonOnTapUP();
          },

           child: ElevatedButton(
              onPressed: (){
                setState(() {
                });
              },
              child: Text(
                PushTranslation,
              ),
            ),
      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
        //まだスピーチを聞いていない場合は、開始します
        _speechToText.isNotListening ? _startListening : _stopListening,
        tooltip: 'Listen',
        child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
