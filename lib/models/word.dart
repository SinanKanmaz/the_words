import 'package:hive_flutter/hive_flutter.dart';

part 'word.g.dart';

@HiveType(typeId: 1)
class Word {
  @HiveField(0)
  String studyLanguage;
  @HiveField(1)
  String nativeLanguage;

  Word({required this.studyLanguage, required this.nativeLanguage});

  @override
  String toString() {
    return 'Word(en: $studyLanguage, tr: $nativeLanguage)';
  }
}
