import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF4A90E2);
const Color secondaryColor = Color(0xFF8E9AAF);
const Color favoriteColor = Color(0xFFEC4899);

Color getPrimaryColor(bool isDarkMode) {
  return isDarkMode ? Color(0xFF8E9AAF) : Color(0xFF4A90E2);
}

final Map<int, String> reverseRoundMapping = {
  1: '2011년 10월',
  2: '2011년 7월',
  3: '2011년 4월',
  4: '2011년 2월',
  5: '2010년 10월',
  6: '2010년 7월',
  7: '2010년 3월',
  8: '2010년 1월',
  9: '2009년 9월',
  10: '2009년 7월',
  11: '2009년 3월',
  12: '2009년 1월',
  13: '2008년 10월',
  14: '2008년 7월',
  15: '2008년 3월',
  16: '2008년 2월',
  17: '2007년 9월',
  18: '2007년 7월',
};


String examSessionToRoundName(dynamic examVal) {
  int? intVal = (examVal is int) ? examVal : int.tryParse(examVal.toString());
  return reverseRoundMapping[intVal] ?? '기타';
}


final List<String> categories = [
  '지게차운전기능사'
];