// game_core.dart
// 게임의 단계(Phase) 정의
enum GamePhase { roleSelect, scanning, lobby, cardPick, ban, pick, battle, end }

/// 배틀 아이템 카드 종류
enum CardType {
  luckyBox, // 복불복카드: 내시간 +30~1분, 상대 -2분~+30초 랜덤
  blind, // 블라인드: 상대 최근 3개 제시어 한턴 블라인드
  history, // 히스토리: 전체 히스토리 10초간 확인
  liar, // 사기꾼: 상대 표시에만 다른 단어 노출, 한턴 후 실제 단어 공개
  doubleAttack, // 더블 어택: 2개 단어, 상대도 同조건, 이의제기 둘 다 체크
}

/// 카드 실제 소유/상태 추적용
class CardItem {
  final CardType type;
  bool isUsed;
  CardItem({required this.type, this.isUsed = false});
}

/// 카드 설명(표시용)
const Map<CardType, String> cardTypeTitle = {
  CardType.luckyBox: '복불복카드',
  CardType.blind: '블라인드',
  CardType.history: '히스토리',
  CardType.liar: '사기꾼',
  CardType.doubleAttack: '더블 어택',
};
const Map<CardType, String> cardTypeDesc = {
  CardType.luckyBox: '내 시간 +30~60초 & 상대방 -2~-1분 또는 +30초 랜덤',
  CardType.blind: '상대 최근 3개 제시어를 한 턴 블라인드',
  CardType.history: '지금까지 제시된 단어 전체를 10초간 확인',
  CardType.liar: '상대에게 다른 단어 표시, 한 턴 후 실제 단어 공개',
  CardType.doubleAttack: '2개 단어 제출, 상대도 2개, 이의제기 시 둘 다 검사',
};
