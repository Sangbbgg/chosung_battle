import 'dart:async';
import 'dart:math';
import 'dart:convert'; 
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';

// 분리한 파일들 가져오기
import 'game_core.dart';
import 'screens/connect_screen.dart';
import 'screens/ban_pick_screen.dart';
import 'screens/battle_screen.dart';
import 'korean_parser.dart'; 
import 'dictionary_service.dart';
// import 'api_key.dart'; 

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: GameController()));
}

class GameController extends StatefulWidget {
  const GameController({super.key});

  @override
  State<GameController> createState() => _GameControllerState();
}

class _GameControllerState extends State<GameController> {
  // === 통신 변수 ===
  final Strategy strategy = Strategy.P2P_STAR;
  String? peerId;
  String myNickName = "플레이어 ${Random().nextInt(999)}";
  String peerNickName = "상대방";
  bool isHost = false;
  Map<String, String> discoveredDevices = {}; 

  // === 게임 변수 ===
  GamePhase phase = GamePhase.roleSelect;
  List<String> initialChars = [];
  String? myBanChar;
  String? peerBanChar;
  String? myPickChar;
  String? peerPickChar;
  String finalKeyword = "";

  int myTime = 480;
  int peerTime = 480;
  int gameCardCount = 3; // 실제 게임에 적용될 카드 수

  bool isMyTurn = false;
  List<String> history = ["???", "???", "???"];
  Set<String> usedWords = {};
  TextEditingController textCtrl = TextEditingController();
  Timer? gameTimer;
  
  int myChallengeCount = 3;
  bool hasChallengedThisTurn = false; 
  bool isCheckingChallenge = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: phase == GamePhase.battle 
            ? (isMyTurn ? Colors.blue : Colors.red) 
            : Colors.indigo,
        actions: [
          if (phase == GamePhase.lobby || phase == GamePhase.ban || phase == GamePhase.pick || phase == GamePhase.battle)
            TextButton.icon(
              icon: const Icon(Icons.flag, color: Colors.white),
              label: const Text("기권", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: confirmGiveUp,
            ),
          if (phase == GamePhase.end || phase == GamePhase.scanning)
             IconButton(
              icon: const Icon(Icons.exit_to_app), 
              onPressed: disconnect,
              tooltip: "나가기",
            ),
        ],
      ),
      body: _buildCurrentScreen(),
    );
  }

  void confirmGiveUp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("🏳️ 기권하시겠습니까?"),
        actions: [
          TextButton(child: const Text("취소"), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("기권 확인"),
            onPressed: () {
              Navigator.pop(ctx);
              sendMessage("SURRENDER", "기권");
              disconnect();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (phase) {
      case GamePhase.roleSelect:
      case GamePhase.scanning:
      case GamePhase.lobby:
        return ConnectScreen(
          isHost: isHost,
          currentPhase: phase,
          myNickName: myNickName,
          discoveredDevices: discoveredDevices,
          gameTime: myTime,
          gameCardCount: gameCardCount,
          onHost: (time, cardCount) => startHosting(time, cardCount),
          onGuest: startDiscovery,
          onRequest: requestConnection,
          onCancel: disconnect,
          onNickNameChanged: (val) => setState(() => myNickName = val),
          onGameStart: startGameSetup,
        );
      
      case GamePhase.ban:
      case GamePhase.pick:
        return BanPickScreen(
          phase: phase,
          initialChars: initialChars,
          myBan: myBanChar,
          peerBan: peerBanChar,
          selectedChar: phase == GamePhase.ban ? myBanChar : myPickChar,
          onSelect: (char) {
            sendMessage(phase == GamePhase.ban ? "BAN" : "PICK", char);
            setState(() {
              if (phase == GamePhase.ban) {
                myBanChar = char;
              } else {
                myPickChar = char;
              }
            });
            checkPhaseProgress();
          },
        );

      case GamePhase.battle:
        return BattleScreen(
          isMyTurn: isMyTurn,
          myTime: myTime,
          peerTime: peerTime,
          keyword: finalKeyword,
          history: history,
          textCtrl: textCtrl,
          myNickName: myNickName,
          peerNickName: peerNickName,
          challengeCount: myChallengeCount,
          isChallengeUsed: hasChallengedThisTurn,
          isChecking: isCheckingChallenge, 
          
          onChallenge: (targetWord) async {
            if (hasChallengedThisTurn || isCheckingChallenge) return;

            setState(() { isCheckingChallenge = true; });
            showSnack("🔍 사전 검색 중...");

            String? definition = await DictionaryService.searchWordDefinition(targetWord);
            
            if (!mounted) return;
            
            setState(() {
              isCheckingChallenge = false;
              
              if (definition != null) {
                // [실패]
                myChallengeCount--; 
                hasChallengedThisTurn = true;
                
                if (myChallengeCount <= 0) {
                   showDialog(
                     context: context,
                     barrierDismissible: false,
                     builder: (ctx) => AlertDialog(
                       title: const Text("❌ 3회 실패! 게임 오버"),
                       content: SingleChildScrollView(child: Text("단어 뜻:\n$definition\n\n기회를 모두 소진하여 패배했습니다.")),
                       actions: [
                         ElevatedButton(
                           onPressed: () {
                             Navigator.pop(ctx);
                             sendMessage("GAME_OVER", "WIN"); 
                             disconnect();
                           },
                           child: const Text("확인"),
                         )
                       ],
                     ),
                   );
                } else {
                  myTime -= 60;
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text("❌ 실패! (남은 기회: $myChallengeCount)"),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("사전에 존재하는 단어입니다.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                              child: Text(definition, style: const TextStyle(fontSize: 14)),
                            ),
                            const SizedBox(height: 10),
                            const Text("내 시간 -60초 페널티!"),
                          ],
                        ),
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("확인"))],
                    ),
                  );
                }
              } else {
                // [성공]
                 showDialog(
                   context: context,
                   barrierDismissible: false,
                   builder: (ctx) => AlertDialog(
                     title: const Text("✅ 이의 제기 성공!"),
                     content: const Text("사전에 없는 단어입니다!\n상대방의 반칙으로 승리했습니다! 🎉"),
                     actions: [
                       ElevatedButton(
                         onPressed: () {
                           Navigator.pop(ctx);
                           sendMessage("GAME_OVER", "LOSE");
                           disconnect();
                         },
                         child: const Text("확인"),
                       )
                     ],
                   ),
                 );
              }
            });
          },
          
          onSubmit: (val) {
             if (val.isEmpty) return;
             if (usedWords.contains(val)) {
               showSnack("이미 쓴 단어! (-10초)");
               setState(() => myTime -= 10);
               return;
             }
             String targetChosung = finalKeyword.replaceAll(" ", ""); 
             String? inputChosung = KoreanParser.extractChosung(val);
             if (inputChosung == null) { showSnack("한글만 입력해주세요!"); return; }
             if (inputChosung != targetChosung) { showSnack("초성이 틀렸습니다! (목표: $targetChosung)"); return; }

             sendMessage("WORD", val);
             processWord(val, true);
          },
        );

      case GamePhase.end:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(myTime > 0 ? "승리! 🎉" : "패배 😭", style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: disconnect, child: const Text("메인으로 돌아가기"))
            ],
          )
        );
    }
  }

  String _getTitle() {
    switch (phase) {
      case GamePhase.roleSelect: return "닉네임 설정";
      case GamePhase.scanning: return isHost ? "도전자 대기 중" : "방 찾는 중";
      case GamePhase.lobby: return "대기실";
      case GamePhase.ban: return "자음 제외 (BAN)";
      case GamePhase.pick: return "자음 선택 (PICK)";
      case GamePhase.battle: return "초성 배틀";
      case GamePhase.end: return "게임 종료";
    }
  }

  void startGameSetup() {
    final chars = ["ㄱ","ㄴ","ㄷ","ㄹ","ㅁ","ㅂ","ㅅ","ㅇ","ㅈ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"];
    chars.shuffle();
    initialChars = chars.sublist(0, 5);
    sendMessage("START_BAN", initialChars.join(","));
    setState(() => phase = GamePhase.ban);
  }

  void checkPhaseProgress() {
    if (phase == GamePhase.ban && myBanChar != null && peerBanChar != null) {
      phase = GamePhase.pick;
    } else if (phase == GamePhase.pick && myPickChar != null && peerPickChar != null) {
      if (isHost) {
        List<String> f = [myPickChar!, peerPickChar!];
        f.shuffle();
        String k = f.join("  ");
        bool hostStarts = Random().nextBool();
        String startToken = hostStarts ? "HOST" : "GUEST";
        sendMessage("START_GAME", "$k:$startToken");
        setState(() {
          finalKeyword = k;
          isMyTurn = hostStarts;
          phase = GamePhase.battle;
          startTimer();
        });
      }
    }
  }

  void startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (phase != GamePhase.battle) return;
      setState(() {
        if (isMyTurn) {
          myTime--;
          if (myTime <= 0) phase = GamePhase.end;
        } else {
          peerTime--;
          if (peerTime <= 0) phase = GamePhase.end;
        }
      });
    });
  }

  void processWord(String word, bool sentByMe) {
    usedWords.add(word);
    history.add(word);
    if (history.length > 3) history.removeAt(0);
    if (sentByMe) textCtrl.clear();
    setState(() {
      isMyTurn = !sentByMe;
      hasChallengedThisTurn = false; 
    });
  }

  // [수정된 startHosting]
  void startHosting(int timeMin, String cardCountStr) async {
    if (myNickName.isEmpty) { showSnack("닉네임을 입력해주세요"); return; }
    
    int setTime = timeMin * 60;
    
    // 실제 게임용 숫자 (내부 저장)
    int finalCardCount;
    if (cardCountStr == "랜덤") {
      finalCardCount = Random().nextInt(5) + 1; // 1~5 랜덤
    } else {
      finalCardCount = int.parse(cardCountStr.replaceAll("장", ""));
    }

    setState(() {
      isHost = true;
      phase = GamePhase.scanning;
      myTime = setTime;
      peerTime = setTime;
      gameCardCount = finalCardCount; // 실제 장수 저장
    });

    // [핵심] 광고용 이름표 (랜덤이면 "랜덤"이라고 보냄)
    String displayCardInfo = (cardCountStr == "랜덤") ? "랜덤" : finalCardCount.toString();
    String advertisingName = "$myNickName|$timeMin|$displayCardInfo";

    try {
      await Nearby().startAdvertising(advertisingName, strategy, onConnectionInitiated: onConnInit, onConnectionResult: (id, s) {
        if(s == Status.CONNECTED) {
          setState(() { peerId = id; phase = GamePhase.lobby; });
          // 연결 후에는 실제 확정된 장수(finalCardCount)를 동기화
          sendMessage("SYNC_SETTINGS", "$myTime:$gameCardCount");
        }
      }, onDisconnected: (id) => disconnect());
    } catch (e) {
      showSnack("오류: $e");
      disconnect();
    }
  }

  void startDiscovery() async {
    if(myNickName.isEmpty) { showSnack("닉네임을 입력해주세요"); return; }
    setState(() { isHost = false; phase = GamePhase.scanning; discoveredDevices.clear(); });
    try {
      await Nearby().startDiscovery(myNickName, strategy, onEndpointFound: (id, name, s) => setState(() => discoveredDevices[id] = name), onEndpointLost: (id) => setState(() => discoveredDevices.remove(id)));
    } catch (e) {
      showSnack("오류: $e");
      disconnect();
    }
  }

  void requestConnection(String id) async {
    try {
      await Nearby().requestConnection(myNickName, id, onConnectionInitiated: onConnInit, onConnectionResult: (id, s) => s == Status.CONNECTED ? setState(() { peerId = id; phase = GamePhase.lobby; }) : null, onDisconnected: (id) => disconnect());
    } catch (e) {
      if (e.toString().contains("8003")) { showSnack("이미 연결 요청을 보냈거나 연결된 상태입니다."); } else { showSnack("오류: $e"); }
    }
  }

  void disconnect() {
    if (peerId != null) Nearby().disconnectFromEndpoint(peerId!);
    Nearby().stopAdvertising(); Nearby().stopDiscovery();
    setState(() { 
      phase = GamePhase.roleSelect; peerId = null; discoveredDevices.clear(); 
      myTime=480; peerTime=480; history=["???","???","???"]; usedWords.clear(); 
      initialChars = []; myBanChar=null; peerBanChar=null; myPickChar=null; peerPickChar=null; 
      peerNickName="상대방"; myChallengeCount=3; hasChallengedThisTurn=false; isCheckingChallenge=false; 
    });
  }

  void onConnInit(String id, ConnectionInfo info) {
    String rawName = info.endpointName;
    String realName = rawName.split("|")[0];

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: Text("$realName님의 연결 요청"),
      actions: [
        TextButton(child: const Text("거절"), onPressed: () { Navigator.pop(ctx); try{Nearby().rejectConnection(id);}catch(e){} }),
        ElevatedButton(child: const Text("수락"), onPressed: () { 
          Navigator.pop(ctx); 
          setState(() { peerNickName = realName; });
          Nearby().acceptConnection(id, onPayLoadRecieved: (id, p) { if(p.type == PayloadType.BYTES) handleMessage(utf8.decode(p.bytes!)); }); 
        }),
      ],
    ));
  }

  void sendMessage(String type, String val) {
    if (peerId != null) {
      String msg = "$type:$val";
      Nearby().sendBytesPayload(peerId!, Uint8List.fromList(utf8.encode(msg)));
    }
  }

  void handleMessage(String msg) {
    List<String> p = msg.split(":");
    String type = p[0]; String val = p.length > 1 ? p[1] : "";
    
    setState(() {
      if (type == "START_BAN") { initialChars = val.split(","); phase = GamePhase.ban; }
      else if (type == "BAN") { peerBanChar = val; checkPhaseProgress(); }
      else if (type == "PICK") { peerPickChar = val; checkPhaseProgress(); }
      else if (type == "START_GAME") { finalKeyword = val; if (p.length > 2) isMyTurn = (p[2] != "HOST"); phase = GamePhase.battle; startTimer(); }
      else if (type == "WORD") { processWord(val, false); }
      else if (type == "SURRENDER") { showSnack("상대방 기권! 승리!"); disconnect(); }
      else if (type == "GAME_OVER") { if (val == "WIN") { phase = GamePhase.end; myTime = 0; } else { phase = GamePhase.end; myTime = 100; } gameTimer?.cancel(); }
      else if (type == "SYNC_SETTINGS") {
        if (p.length > 2) {
          int tVal = int.parse(p[1]);
          myTime = tVal; peerTime = tVal;
          gameCardCount = int.parse(p[2]);
        }
      }
    });
  }

  void showSnack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), duration: const Duration(milliseconds: 1500)));
}