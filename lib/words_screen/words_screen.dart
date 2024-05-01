import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:the_words/models/word.dart';
import 'package:the_words/widgets/custom_alert_dialog.dart';
import 'package:the_words/words_screen/widgets/flip_card.dart';

class MyWordsScreen extends StatefulWidget {
  const MyWordsScreen({super.key});

  @override
  State<MyWordsScreen> createState() => _MyWordsScreenState();
}

class _MyWordsScreenState extends State<MyWordsScreen> {
  Box box = Hive.box<Word>('words');
  final _formKey = GlobalKey<FormState>();
  late FlutterTts flutterTts;

  late Word _word;
  late String _newWordTr;
  late String _newWordEn;
  int? index;
  String userLang = "en";

  bool isBusy = true;
  @override
  void initState() {
    super.initState();
    findWord();
    initTts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  initTts() async {
    String language;
    flutterTts = FlutterTts();
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    switch (userLang) {
      case 'en':
        language = 'en-US';
        break;
      case 'de':
        language = 'de-DE';
        break;
      case 'fr':
        language = 'fr-FR';
        break;
      case 'tr':
        language = 'tr-TR';
        break;
      default:
        language = 'en-US';
    }
    flutterTts.setLanguage(language);
  }

  void findWord() async {
    if (box.isNotEmpty) {
      Random random = Random();
      index = random.nextInt(box.length);
      _word = box.getAt(index!);
    } else {
      index = null;
    }
    isBusy = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/images/bg.png'), fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'My Words: ${box.length}',
            style: const TextStyle(fontSize: 20),
          ),
          actions: [
            if (box.isNotEmpty)
              IconButton(
                onPressed: () {
                  flutterTts.speak(_word.studyLanguage);
                },
                icon: const Icon(Icons.volume_up),
              ),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => CustomAlertDialog(
                    body: "This screen is designed to memorize new words",
                    accept: () => Navigator.pop(context),
                    acceptText: "Ok",
                  ),
                );
              },
              icon: const Icon(Icons.info),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: isBusy
                  ? const Center(
                      child: CircularProgressIndicator.adaptive(),
                    )
                  : box.isEmpty
                      ? Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            "You have not saved a word yet you can start using by saving the first word",
                            style: Theme.of(context).textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          child: FlipCard(
                            front: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                _word.studyLanguage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            back: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white54,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                _word.nativeLanguage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
            )
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (index != null)
                  FloatingActionButton(
                    heroTag: 1,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CustomAlertDialog(
                          title:
                              "Are you sure you want to delete the ${_word.studyLanguage}",
                          accept: () async {
                            await box.deleteAt(index!);
                            index = null;
                            findWord();
                            Navigator.pop(context);
                          },
                          reject: () => Navigator.pop(context),
                          acceptText: "Ok",
                          rejectText: "Cancel",
                        ),
                      );
                    },
                    backgroundColor: Colors.red,
                    child: const Icon(CupertinoIcons.trash),
                  ),
                if (index != null)
                  FloatingActionButton(
                    heroTag: 2,
                    onPressed: () {
                      showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                                title: const Text("Add a new word"),
                                content: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      CupertinoTextFormFieldRow(
                                        placeholder: "Study language",
                                        initialValue: _word.studyLanguage,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value!.trim().isNotEmpty) {
                                            return null;
                                          } else {
                                            return "Missing information";
                                          }
                                        },
                                        onSaved: (value) {
                                          _newWordEn = value!;
                                        },
                                      ),
                                      CupertinoTextFormFieldRow(
                                        placeholder: "Native language",
                                        initialValue: _word.nativeLanguage,
                                        validator: (value) {
                                          if (value!.trim().isNotEmpty) {
                                            return null;
                                          } else {
                                            return "Missing information";
                                          }
                                        },
                                        onSaved: (value) {
                                          _newWordTr = value!;
                                        },
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text("Cancel"),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  CupertinoDialogAction(
                                    child: const Text("Add"),
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        _formKey.currentState!.save();
                                        Word word = Word(
                                            studyLanguage: _newWordEn,
                                            nativeLanguage: _newWordTr);
                                        await box.putAt(index!, word);
                                        findWord();
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ],
                              ));
                    },
                    backgroundColor: Colors.cyan,
                    child: const Icon(Icons.edit),
                  ),
                FloatingActionButton(
                  heroTag: 4,
                  backgroundColor: Colors.green,
                  onPressed: () {
                    showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                              title: const Text("Add a new word"),
                              content: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    CupertinoTextFormFieldRow(
                                      placeholder: "Study language",
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value!.trim().isNotEmpty) {
                                          return null;
                                        } else {
                                          return "Missing information";
                                        }
                                      },
                                      onSaved: (value) {
                                        _newWordEn = value!;
                                      },
                                    ),
                                    CupertinoTextFormFieldRow(
                                      placeholder: "Native language",
                                      validator: (value) {
                                        if (value!.trim().isNotEmpty) {
                                          return null;
                                        } else {
                                          return "Missing information";
                                        }
                                      },
                                      onSaved: (value) {
                                        _newWordTr = value!;
                                      },
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text("Cancel"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                CupertinoDialogAction(
                                  child: const Text("Add"),
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      Word word = Word(
                                          studyLanguage: _newWordEn,
                                          nativeLanguage: _newWordTr);
                                      await box.add(word);
                                      findWord();
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ],
                            ));
                  },
                  child: const Icon(Icons.add_circle),
                ),
                FloatingActionButton(
                  onPressed: () {
                    findWord();
                  },
                  heroTag: 3,
                  child: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // void setNotification() async {
  //   LocalNotificationService.initialize();
  //   LocalNotificationService.showDailyWordsNotification(
  //       0,
  //       AppLocalizations.of(context)!
  //           .you_havent_repeated_a_word_in_the_last_24_hours,
  //       AppLocalizations.of(context)!
  //           .learning_a_language_cannot_be_neglected_you_should_repeat_at_least_once_a_day);
  // }
}
