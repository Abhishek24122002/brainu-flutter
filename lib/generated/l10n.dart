// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Brainu is in a dense forest to identify different varieties of leaves and flowers. \n \n Help Brainu Identify the different consonants too. Listen to the options given and choose the correct one.`
  String get vc_starting_question {
    return Intl.message(
      'Brainu is in a dense forest to identify different varieties of leaves and flowers. \n \n Help Brainu Identify the different consonants too. Listen to the options given and choose the correct one.',
      name: 'vc_starting_question',
      desc: '',
      args: [],
    );
  }

  /// `Click here to Start`
  String get click_here_to_start {
    return Intl.message(
      'Click here to Start',
      name: 'click_here_to_start',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message(
      'Submit',
      name: 'submit',
      desc: '',
      args: [],
    );
  }

  /// `Letter`
  String get letter {
    return Intl.message(
      'Letter',
      name: 'letter',
      desc: '',
      args: [],
    );
  }

  /// `Games`
  String get games {
    return Intl.message(
      'Games',
      name: 'games',
      desc: '',
      args: [],
    );
  }

  /// `Select Your Games`
  String get select_your_games {
    return Intl.message(
      'Select Your Games',
      name: 'select_your_games',
      desc: '',
      args: [],
    );
  }

  /// `Help Brainu to understand what is pinned on the board. \nCertain items will appear on the notes. Say them out loud from left to right as fast as you can.`
  String get ran_question {
    return Intl.message(
      'Help Brainu to understand what is pinned on the board. \nCertain items will appear on the notes. Say them out loud from left to right as fast as you can.',
      name: 'ran_question',
      desc: '',
      args: [],
    );
  }

  /// `Brainu is at the beach. He is holding a board that will show a few words. Help him read them out by recording your answer. The word will appear only when you tap.`
  String get word_reading_question {
    return Intl.message(
      'Brainu is at the beach. He is holding a board that will show a few words. Help him read them out by recording your answer. The word will appear only when you tap.',
      name: 'word_reading_question',
      desc: '',
      args: [],
    );
  }

  /// `Brainu is in a quiet and peaceful forest, \n to listen to the sounds of birds and nature. Words will be dictated. \nHelp Brain by typing the word that is dictated!`
  String get dictation_consonent {
    return Intl.message(
      'Brainu is in a quiet and peaceful forest, \n to listen to the sounds of birds and nature. Words will be dictated. \nHelp Brain by typing the word that is dictated!',
      name: 'dictation_consonent',
      desc: '',
      args: [],
    );
  }

  /// `Brainu wants to listen to a story but he is not able to read. But you can help him! Please read out the short story from his story book. It will appear after you tap Start.`
  String get paragraph_reading_question {
    return Intl.message(
      'Brainu wants to listen to a story but he is not able to read. But you can help him! Please read out the short story from his story book. It will appear after you tap Start.',
      name: 'paragraph_reading_question',
      desc: '',
      args: [],
    );
  }

  /// `To help Brainu perform the Spoonerism Step, exchange the first letters of the pair of words and tell Brainu what the new pair is! Tap on the words to listen. Tap START to begin`
  String get spoonerism_question {
    return Intl.message(
      'To help Brainu perform the Spoonerism Step, exchange the first letters of the pair of words and tell Brainu what the new pair is! Tap on the words to listen. Tap START to begin',
      name: 'spoonerism_question',
      desc: '',
      args: [],
    );
  }

  /// `Help Brainu by telling him what the remaining word would be, after you remove the specific sound from the given word. Tap on sound and  word icons to listen to the audio.`
  String get phoneme_deletion_question {
    return Intl.message(
      'Help Brainu by telling him what the remaining word would be, after you remove the specific sound from the given word. Tap on sound and  word icons to listen to the audio.',
      name: 'phoneme_deletion_question',
      desc: '',
      args: [],
    );
  }

  /// `Help Brainu by telling him what new word will be formed when sound 1 is substituted with sound 2 in the given word. \nTap on sound 1, sound 2, and word icons for audio.`
  String get phoneme_substitution_question {
    return Intl.message(
      'Help Brainu by telling him what new word will be formed when sound 1 is substituted with sound 2 in the given word. \nTap on sound 1, sound 2, and word icons for audio.',
      name: 'phoneme_substitution_question',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get done {
    return Intl.message(
      'Done',
      name: 'done',
      desc: '',
      args: [],
    );
  }

  /// `Letter`
  String get game_letter {
    return Intl.message(
      'Letter',
      name: 'game_letter',
      desc: '',
      args: [],
    );
  }

  /// `Identify`
  String get game_identify {
    return Intl.message(
      'Identify',
      name: 'game_identify',
      desc: '',
      args: [],
    );
  }

  /// `Word`
  String get game_word {
    return Intl.message(
      'Word',
      name: 'game_word',
      desc: '',
      args: [],
    );
  }

  /// `Listen`
  String get game_listen {
    return Intl.message(
      'Listen',
      name: 'game_listen',
      desc: '',
      args: [],
    );
  }

  /// `Story`
  String get game_story {
    return Intl.message(
      'Story',
      name: 'game_story',
      desc: '',
      args: [],
    );
  }

  /// `Swapping`
  String get game_swapping {
    return Intl.message(
      'Swapping',
      name: 'game_swapping',
      desc: '',
      args: [],
    );
  }

  /// `Word Game 1`
  String get game_word_game1 {
    return Intl.message(
      'Word Game 1',
      name: 'game_word_game1',
      desc: '',
      args: [],
    );
  }

  /// `Word Game 2`
  String get game_word_game2 {
    return Intl.message(
      'Word Game 2',
      name: 'game_word_game2',
      desc: '',
      args: [],
    );
  }

  /// `Word Game 3`
  String get game_word_game3 {
    return Intl.message(
      'Word Game 3',
      name: 'game_word_game3',
      desc: '',
      args: [],
    );
  }

  /// `Word Game 4`
  String get game_word_game4 {
    return Intl.message(
      'Word Game 4',
      name: 'game_word_game4',
      desc: '',
      args: [],
    );
  }

  /// `Stop Recording`
  String get stop_recording {
    return Intl.message(
      'Stop Recording',
      name: 'stop_recording',
      desc: '',
      args: [],
    );
  }

  /// `Start Recording`
  String get start_recording {
    return Intl.message(
      'Start Recording',
      name: 'start_recording',
      desc: '',
      args: [],
    );
  }

  /// `Play Audio`
  String get play_audio {
    return Intl.message(
      'Play Audio',
      name: 'play_audio',
      desc: '',
      args: [],
    );
  }

  /// `Stop Audio`
  String get stop_audio {
    return Intl.message(
      'Stop Audio',
      name: 'stop_audio',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get confirm {
    return Intl.message(
      'Confirm',
      name: 'confirm',
      desc: '',
      args: [],
    );
  }

  /// `Ants are found everywhere in the world. They make their home in buildings, gardens etc. They live in anthills. Ants are very hardworking insects. Throughout the summers they collect food for the winter season. Whenever they find a sweet lying on the floor they stick to the sweet and carry it to their home.`
  String get paragraph_reading_0 {
    return Intl.message(
      'Ants are found everywhere in the world. They make their home in buildings, gardens etc. They live in anthills. Ants are very hardworking insects. Throughout the summers they collect food for the winter season. Whenever they find a sweet lying on the floor they stick to the sweet and carry it to their home.',
      name: 'paragraph_reading_0',
      desc: '',
      args: [],
    );
  }

  /// `Today is Holi the festival of colours. Ranis brother Ravi and their parents have got ready with white clothes and have bought colourful eco friendly packets of colours. They include pink gulal, red vermilion, yellow turmeric and green leaf powder colour. They are ready to play dry holi with minimum wastage of water and lots of happiness, unity, sweets and treats.`
  String get paragraph_reading_1 {
    return Intl.message(
      'Today is Holi the festival of colours. Ranis brother Ravi and their parents have got ready with white clothes and have bought colourful eco friendly packets of colours. They include pink gulal, red vermilion, yellow turmeric and green leaf powder colour. They are ready to play dry holi with minimum wastage of water and lots of happiness, unity, sweets and treats.',
      name: 'paragraph_reading_1',
      desc: '',
      args: [],
    );
  }

  /// `There is a candy shop in Hoshiyaarpur. Ramu Bhaiyya is the owner of the shop and sells all types of candies, sweet and sour treats, chocolates and toffees. He has colourful candies, jelly candies and digestive confectioneries. He loves to sell these as children from all over the town come to his shop to buy these. He is a very kind man and often gives free sweets.`
  String get paragraph_reading_2 {
    return Intl.message(
      'There is a candy shop in Hoshiyaarpur. Ramu Bhaiyya is the owner of the shop and sells all types of candies, sweet and sour treats, chocolates and toffees. He has colourful candies, jelly candies and digestive confectioneries. He loves to sell these as children from all over the town come to his shop to buy these. He is a very kind man and often gives free sweets.',
      name: 'paragraph_reading_2',
      desc: '',
      args: [],
    );
  }

  /// `once upon a time. The three bulls were very good friends among themselves. They used to go to graze grass together. A lion had been following them all for many days, but he knew that as long as these three are united, he cannot spoil them. The lion did the trick to separate the three from each other. He started blowing rumors about Ballo. After hearing the rumors, misunderstanding arose between them. Gradually they started burning with each other. Eventually one day they got into a fight and they started living separately. This was a great opportunity for the lion. He took full advantage of it and killed all three one by one and ate.\nlearning - There is power in unity.`
  String get paragraph_reading_3 {
    return Intl.message(
      'once upon a time. The three bulls were very good friends among themselves. They used to go to graze grass together. A lion had been following them all for many days, but he knew that as long as these three are united, he cannot spoil them. The lion did the trick to separate the three from each other. He started blowing rumors about Ballo. After hearing the rumors, misunderstanding arose between them. Gradually they started burning with each other. Eventually one day they got into a fight and they started living separately. This was a great opportunity for the lion. He took full advantage of it and killed all three one by one and ate.\nlearning - There is power in unity.',
      name: 'paragraph_reading_3',
      desc: '',
      args: [],
    );
  }

  /// ``
  String get paragraph_reading_4 {
    return Intl.message(
      '',
      name: 'paragraph_reading_4',
      desc: '',
      args: [],
    );
  }

  /// ``
  String get paragraph_reading_5 {
    return Intl.message(
      '',
      name: 'paragraph_reading_5',
      desc: '',
      args: [],
    );
  }

  /// `Sound`
  String get sound {
    return Intl.message(
      'Sound',
      name: 'sound',
      desc: '',
      args: [],
    );
  }

  /// `Sound 1`
  String get sound1 {
    return Intl.message(
      'Sound 1',
      name: 'sound1',
      desc: '',
      args: [],
    );
  }

  /// `Sound 2`
  String get sound2 {
    return Intl.message(
      'Sound 2',
      name: 'sound2',
      desc: '',
      args: [],
    );
  }

  /// `Word`
  String get Word {
    return Intl.message(
      'Word',
      name: 'Word',
      desc: '',
      args: [],
    );
  }

  /// `substitute`
  String get substitute {
    return Intl.message(
      'substitute',
      name: 'substitute',
      desc: '',
      args: [],
    );
  }

  /// `With`
  String get With {
    return Intl.message(
      'With',
      name: 'With',
      desc: '',
      args: [],
    );
  }

  /// `in`
  String get In {
    return Intl.message(
      'in',
      name: 'In',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get Remove {
    return Intl.message(
      'Remove',
      name: 'Remove',
      desc: '',
      args: [],
    );
  }

  /// `From the`
  String get from_the {
    return Intl.message(
      'From the',
      name: 'from_the',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'hi'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
