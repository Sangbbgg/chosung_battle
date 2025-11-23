import 'package:flutter/material.dart';
import '../game_core.dart';

class BattleScreen extends StatelessWidget {
  final bool isMyTurn;
  final int myTime;
  final int peerTime;
  final String keyword;
  final List<String> history;
  final TextEditingController textCtrl;
  final Function(String) onSubmit;
  final String myNickName;
  final String peerNickName;
  final Function(String) onChallenge;
  final bool isChallengeUsed;
  final bool isChecking;
  // [추가] 내 카드 현황 & 카드 사용 콜백
  final List<CardItem> myCardItems;
  final void Function(CardType) onCardUse;

  const BattleScreen({
    super.key,
    required this.isMyTurn,
    required this.myTime,
    required this.peerTime,
    required this.keyword,
    required this.history,
    required this.textCtrl,
    required this.onSubmit,
    required this.myNickName,
    required this.peerNickName,
    required this.onChallenge,
    required this.isChallengeUsed,
    required this.isChecking,
    required this.myCardItems,
    required this.onCardUse,
  });

  @override
  Widget build(BuildContext context) {
    // 리스트의 마지막(가장 최신) 단어를 가져옴
    String? lastWord = history.last == "???" ? null : history.last;
    Color btnColor = (isChallengeUsed) ? Colors.red : Colors.orange;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // [1] 상단 통합 스코어보드
          _buildTopScoreboard(),

          // [2] 메인 게임 영역
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // (좌측) 제시어
                        Text(
                          keyword,
                          style: const TextStyle(
                            fontSize: 90,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 15,
                          ),
                        ),

                        const SizedBox(width: 30),

                        // (우측) 히스토리 - [수정됨]
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                          // .reversed를 삭제하여 순서대로(위->아래) 출력
                          children: history.map((w) {
                            // 가장 최신 단어(마지막)인지 확인
                            bool isLatest = (w == history.last && w != "???");

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(
                                w,
                                style: TextStyle(
                                  fontSize: 22,
                                  // 최신 단어는 진하게, 옛날 단어는 연하게
                                  color: w == "???"
                                      ? Colors.grey[300]
                                      : (isLatest
                                            ? Colors.black
                                            : Colors.grey[500]),
                                  fontWeight: isLatest
                                      ? FontWeight.w900
                                      : FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 이의 제기 버튼
                    if (isMyTurn && lastWord != null)
                      if (isChecking)
                        _buildLoadingButton()
                      else if (!isChallengeUsed)
                        _buildChallengeButton(btnColor, lastWord)
                      else
                        _buildDisabledButton(),
                  ],
                ),
              ),
            ),
          ),

          // [3] 하단 입력창
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: TextField(
              controller: textCtrl,
              enabled: true,
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: isMyTurn ? "단어를 입력하세요" : "상대방 차례입니다",
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.send,
                    color: isMyTurn ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _handleSend(context),
                ),
              ),
              onSubmitted: (_) => _handleSend(context),
            ),
          ),
          // [추가] 카드 바 표시
          buildCardBar(),
        ],
      ),
    );
  }

  Widget _buildTopScoreboard() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              color: isMyTurn ? Colors.blue[50] : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          myNickName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatTime(myTime),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isMyTurn ? Colors.blue : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: Container(
              color: !isMyTurn ? Colors.red[50] : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          peerNickName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatTime(peerTime),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: !isMyTurn ? Colors.red : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.person_outline, color: Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeButton(Color color, String word) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
      ),
      icon: const Icon(Icons.front_hand),
      label: Text(
        "'$word' 이의 제기",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: () => onChallenge(word),
    );
  }

  Widget _buildLoadingButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.grey[700],
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      icon: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
      ),
      label: const Text(
        "사전 확인 중...",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: null,
    );
  }

  Widget _buildDisabledButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.grey[400],
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      icon: const Icon(Icons.check),
      label: Text(
        "이의 제기 완료",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: null,
    );
  }

  void _handleSend(BuildContext context) {
    if (!isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✋ 아직 상대방 차례입니다!"),
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }
    onSubmit(textCtrl.text);
  }

  String _formatTime(int sec) {
    return "${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}";
  }

  Widget buildCardBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: myCardItems.map((cardItem) {
          bool used = cardItem.isUsed;
          return GestureDetector(
            onTap: used ? null : () => onCardUse(cardItem.type),
            child: Opacity(
              opacity: used ? 0.5 : 1.0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: used ? Colors.grey : Colors.orange,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  color: used ? Colors.grey[200] : Colors.orange[100],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 카드 아이콘은 실제 구현 시 더욱 다채롭게 커스텀 가능
                    Icon(
                      Icons.local_fire_department,
                      color: used ? Colors.grey : Colors.orange,
                      size: 32,
                    ),
                    Text(
                      cardTypeTitle[cardItem.type]!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: used ? Colors.grey : Colors.orange,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
