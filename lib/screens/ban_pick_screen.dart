import 'package:flutter/material.dart';
import '../game_core.dart';

class BanPickScreen extends StatelessWidget {
  final GamePhase phase;
  final List<String> initialChars;
  final String? myBan;
  final String? peerBan;
  final Function(String) onSelect;
  final String? selectedChar; // 내가 현재 선택한 자음 (Ban 또는 Pick)

  const BanPickScreen({
    super.key,
    required this.phase,
    required this.initialChars,
    required this.myBan,
    required this.peerBan,
    required this.onSelect,
    required this.selectedChar,
  });

  @override
  Widget build(BuildContext context) {
    String title = phase == GamePhase.ban ? "제외할 자음 선택 (BAN)" : "사용할 자음 선택 (PICK)";
    
    // 보여줄 자음 리스트 만들기
    List<String> displayChars = List.from(initialChars);
    
    // [PICK 단계]일 때는 이미 밴 된 글자는 목록에서 아예 지워버림
    if (phase == GamePhase.pick) {
      displayChars.remove(myBan);
      displayChars.remove(peerBan);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // 설명 텍스트 추가
          if (phase == GamePhase.ban)
            const Text("상대방이 선택한 자음은 붉게 표시됩니다.", style: TextStyle(color: Colors.grey)),
          
          const SizedBox(height: 30),
          
          Wrap(
            spacing: 15, 
            runSpacing: 15,
            alignment: WrapAlignment.center, // 가운데 정렬
            children: displayChars.map((char) {
              
              // 1. 상태 확인
              bool isMe = (selectedChar == char);
              // BAN 단계일 때만 상대방 밴 정보를 보여줌
              bool isPeer = (phase == GamePhase.ban && peerBan == char);
              bool isBoth = isMe && isPeer; // 둘 다 같은 걸 골랐을 때

              // 2. 디자인 결정 (색상 및 테두리)
              Color bgColor = Colors.white;
              Color borderColor = Colors.grey;
              String label = char;
              TextStyle textStyle = const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black);

              if (isBoth) {
                // 둘 다 선택함
                bgColor = Colors.orangeAccent;
                borderColor = Colors.deepOrange;
                label = "$char\n(같이)";
                textStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white);
              } else if (isMe) {
                // 나만 선택함
                bgColor = Colors.amber;
                borderColor = Colors.amberAccent;
              } else if (isPeer) {
                // 상대만 선택함
                bgColor = Colors.red.shade100;
                borderColor = Colors.red;
                label = "$char\n(상대)";
                textStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red);
              }

              return GestureDetector(
                // 이미 내가 골랐으면 취소 불가(로직에 따라 다름), 여기선 단순 탭
                onTap: selectedChar == null ? () => onSelect(char) : null,
                child: Container(
                  width: 80, height: 80, // 크기 조금 키움
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: borderColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      )
                    ]
                  ),
                  child: Text(label, textAlign: TextAlign.center, style: textStyle),
                ),
              );
            }).toList(),
          ),
          
          // 하단 상태 메시지
          if (selectedChar != null) 
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text(
                    phase == GamePhase.ban && peerBan == null 
                    ? "상대방이 밴 하는 중..." 
                    : "상대방을 기다리는 중...",
                    style: const TextStyle(color: Colors.grey, fontSize: 18)
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}