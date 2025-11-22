import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_key.dart';

class DictionaryService {
  // 여기에 발급받은 키가 잘 들어있는지 확인하세요!
  static const String apiKey = dictionaryApiKey; 

  static Future<String?> searchWordDefinition(String word) async {
    if (apiKey == "YOUR_API_KEY_HERE") {
      await Future.delayed(const Duration(seconds: 1));
      return "$word : 테스트용 정의입니다."; 
    }

    try {
      String encodedWord = Uri.encodeComponent(word);
      // req_type=json 뒤에 q=word를 붙임
      String url = "https://stdict.korean.go.kr/api/search.do?key=$apiKey&req_type=json&q=$encodedWord";
      
      debugPrint("검색 시도: $url"); // [디버깅] 주소 확인

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // 공백이거나 결과가 없으면
        if (response.body.trim().isEmpty) {
          debugPrint("결과 없음: Body가 비어있음");
          return null;
        }

        var data = jsonDecode(response.body);
        
        // 데이터 구조 안전하게 파싱
        if (data['channel'] != null && data['channel']['item'] != null) {
          List items = data['channel']['item'];
          if (items.isNotEmpty) {
            // 첫 번째 검색 결과
            var firstItem = items[0];
            
            // 'sense'가 리스트일 수도 있고, 하나짜리 객체일 수도 있음 (API 특성)
            var sense = firstItem['sense'];
            String definition = "";

            if (sense is List) {
              definition = sense[0]['definition'];
            } else if (sense is Map) {
              definition = sense['definition'];
            } else {
              return null;
            }
            
            // 특수문자 제거
            return definition.replaceAll(RegExp(r'<[^>]*>'), '');
          }
        }
      } else {
        debugPrint("서버 에러: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ 사전 검색 에러 발생: $e");
      // 인터넷 권한이 없으면 여기서 SocketException이 뜹니다.
    }
    return null;
  }
}