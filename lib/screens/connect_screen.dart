import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../game_core.dart';

class ConnectScreen extends StatefulWidget {
  final bool isHost;
  final GamePhase currentPhase;
  final String myNickName;
  final Map<String, String> discoveredDevices;
  final Function(int time, String cardCount) onHost; // ← 수정
  final Function() onGuest;
  final Function(String) onRequest;
  final Function() onCancel;
  final Function(String) onNickNameChanged;
  final int gameTime;
  final int gameCardCount;
  final VoidCallback? onGameStart;

  const ConnectScreen({
    super.key,
    required this.isHost,
    required this.currentPhase,
    required this.myNickName,
    required this.discoveredDevices,
    required this.onHost,
    required this.onGuest,
    required this.onRequest,
    required this.onCancel,
    required this.onNickNameChanged,
    required this.gameTime,
    required this.gameCardCount,
    this.onGameStart,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  late TextEditingController _nickController;
  bool _isConfiguringHost = false;
  int _selectedTime = 8;
  String _selectedCardCount = "3장";
  final List<int> _timeOptions = [3, 5, 8];
  final List<String> _cardOptions = ["1장", "2장", "3장", "4장", "5장", "랜덤"];

  @override
  void initState() {
    super.initState();
    _nickController = TextEditingController(text: widget.myNickName);
  }

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentPhase == GamePhase.lobby) {
      return _buildLobbyUI();
    } else if (widget.currentPhase == GamePhase.scanning) {
      return _buildScanningUI();
    } else if (_isConfiguringHost) {
      return _buildHostConfigUI();
    } else {
      return _buildRoleSelectUI();
    }
  }

  // [1. 로비 UI - 연결 완료 후 대기 화면]
  Widget _buildLobbyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            "연결되었습니다!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),

          // 게임 설정 정보 카드
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const Text(
                  "게임 설정",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("⏱️ 시간 제한", style: TextStyle(fontSize: 18)),
                    Text(
                      "${widget.gameTime ~/ 60}분",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("🃏 복불복 카드", style: TextStyle(fontSize: 18)),
                    Text(
                      "${widget.gameCardCount}장",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 50),

          if (widget.isHost)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: widget.onGameStart,
              child: const Text(
                "게임 시작",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          else
            Column(
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text(
                  "방장이 게임을 시작하길 기다리는 중...",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // [2. 역할 선택 UI - 닉네임 입력 및 모드 선택]
  Widget _buildRoleSelectUI() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("사용할 닉네임을 입력하세요", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: TextField(
                controller: _nickController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: "닉네임 입력",
                  border: UnderlineInputBorder(),
                ),
                onChanged: widget.onNickNameChanged,
              ),
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              icon: const Icon(Icons.security),
              label: const Text("권한 허용 (최초 1회 필수)"),
              onPressed: () async {
                await [
                  Permission.location,
                  Permission.bluetooth,
                  Permission.bluetoothAdvertise,
                  Permission.bluetoothConnect,
                  Permission.bluetoothScan,
                  Permission.nearbyWifiDevices,
                ].request();
              },
            ),
            const SizedBox(height: 40),

            // 방 만들기 / 방 찾기 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSimpleButton(
                  "방 만들기\n(Host)",
                  Colors.orange,
                  () => setState(() => _isConfiguringHost = true),
                ),
                const SizedBox(width: 20),
                _buildSimpleButton(
                  "방 찾기\n(Guest)",
                  Colors.blue,
                  widget.onGuest,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // [3. 호스트 설정 UI - 시간/카드 설정]
  Widget _buildHostConfigUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "방 설정",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 50),
          _buildDropdownRow(
            "카드 수량",
            _selectedCardCount,
            _cardOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            (val) => setState(() => _selectedCardCount = val.toString()),
          ),
          const SizedBox(height: 20),
          _buildDropdownRow(
            "시  간",
            _selectedTime,
            _timeOptions
                .map((e) => DropdownMenuItem(value: e, child: Text("$e분")))
                .toList(),
            (val) => setState(() => _selectedTime = val as int),
          ),
          const SizedBox(height: 80),

          // 방 만들기 / 돌아가기 버튼 (심플 스타일)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSimpleButton(
                "방 만들기\n(Start)",
                Colors.orange,
                () => widget.onHost(
                  _selectedTime,
                  _selectedCardCount,
                ), // objectionCount 삭제
              ),
              const SizedBox(width: 20),
              _buildSimpleButton(
                "돌아가기\n(Back)",
                Colors.grey,
                () => setState(() => _isConfiguringHost = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // [4. 스캔 UI - 호스트 대기 & 게스트 검색]
  Widget _buildScanningUI() {
    return Column(
      children: [
        if (widget.isHost)
          // [호스트 대기 화면] - 중앙 정렬
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "도전자 대기 중...",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.myNickName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "의 방",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "$_selectedTime분",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Icon(
                              Icons.style,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _selectedCardCount,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // [게스트 검색 화면]
          const LinearProgressIndicator(),
          const Padding(padding: EdgeInsets.all(8), child: Text("방을 찾는 중...")),
          Expanded(
            child: widget.discoveredDevices.isEmpty
                ? const Center(
                    child: Text(
                      "발견된 방이 없습니다.\n잠시 기다려 주세요.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.discoveredDevices.length,
                    itemBuilder: (ctx, i) {
                      String id = widget.discoveredDevices.keys.elementAt(i);
                      String rawName = widget.discoveredDevices[id]!;

                      // 이름표 파싱 (이름|시간|카드)
                      List<String> parts = rawName.split("|");
                      String realName = parts[0];
                      String timeInfo = "?";
                      String cardInfo = "?";
                      if (parts.length >= 3) {
                        timeInfo = parts[1];
                        // 랜덤이면 "장" 생략, 숫자면 "장" 붙임
                        cardInfo = (parts[2] == "랜덤") ? "랜덤" : "${parts[2]}장";
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.gamepad, color: Colors.white),
                          ),
                          title: Text(
                            realName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$timeInfo분",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                const Icon(
                                  Icons.style,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cardInfo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("신청"),
                            onPressed: () => widget.onRequest(id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: 200,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text(
              "취소",
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              setState(() => _isConfiguringHost = false);
              widget.onCancel();
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // [헬퍼 위젯] 드롭다운
  Widget _buildDropdownRow(
    String label,
    dynamic value,
    List<DropdownMenuItem<Object>> items,
    Function(Object?) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton(
              value: value,
              items: items,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 20, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  // [헬퍼 위젯] 심플 버튼 (원래 디자인)
  Widget _buildSimpleButton(String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 140,
      height: 140,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2), // 반투명
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0, // 플랫한 느낌
        ),
        onPressed: onTap,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
