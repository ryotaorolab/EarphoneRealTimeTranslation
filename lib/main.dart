import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';

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

  /// 音声認識セッションを開始するたびに
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
    setState(() {
      Text_Translation(_lastWords);
    });
  }

  /// アクティブな音声認識セッションを手動で停止します
  /// 各プラットフォームが適用するタイムアウトもあり、SpeechToText プラグインはリッスン
  /// メソッドでのタイムアウトの設定をサポートしていることに注意してください。
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// これは、プラットフォームが認識した単語を返すときにSpeechToTextプラグインが呼び出すコールバックです
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      setState(() {
        Text_Translation(_lastWords);
      });
    });
  }


  var translation = "";
  Text_Translation(String lastwords) async {
    final translator = GoogleTranslator();
    translation = (await translator.translate(_lastWords, from: 'ja', to: 'en')).text;
  }

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
                          ? '$_lastWords'
                          : _speechEnabled
                          ? 'マイクをタップして聞き取りを開始します...'
                          : 'スピーチは利用できません',
                    ),
                    Text(
                      translation,
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: (){
                setState(() {
                  Text_Translation(_lastWords);
                });
              },
              child: Text(
                "翻訳",
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
