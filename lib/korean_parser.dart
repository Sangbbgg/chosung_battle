class KoreanParser {
  // 한글 초성 리스트 (유니코드 순서)
  static const List<String> chosungList = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 
    'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
  ];

  // 단어를 넣으면 초성만 뽑아서 돌려주는 함수
  // 예: "가로" -> "ㄱㄹ", "Hello" -> null (한글 아님)
  static String? extractChosung(String word) {
    StringBuffer result = StringBuffer();

    for (int i = 0; i < word.length; i++) {
      int charCode = word.codeUnitAt(i);

      // 한글 유니코드 범위: 0xAC00(가) ~ 0xD7A3(힣)
      if (charCode >= 0xAC00 && charCode <= 0xD7A3) {
        // 공식: (글자코드 - 0xAC00) / 28 / 21 = 초성 인덱스
        int chosungIndex = (charCode - 0xAC00) ~/ 588;
        result.write(chosungList[chosungIndex]);
      } else {
        // 한글이 아닌 글자(영어, 숫자 등)가 섞여있으면 실패 처리
        return null;
      }
    }
    return result.toString();
  }
}