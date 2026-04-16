import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/api/omi_models.dart';
import 'omi_endpoints.dart';

class OmiSyncService {
  OmiSyncService._();

  static OmiSyncService? _instance;
  static OmiSyncService get instance => _instance ??= OmiSyncService._();

  final _uuid = const Uuid();

  Future<OmiSyncResult> processTranscript(String transcript) async {
    debugPrint('OmiSyncService: Processing transcript: ${transcript.substring(0, transcript.length > 100 ? 100 : transcript.length)}...');

    final detectedLanguage = _detectLanguage(transcript) ?? 'en';
    debugPrint('OmiSyncService: Detected language: $detectedLanguage');

    String? conversationId;
    String? memoryId;
    final List<String> actionItemIds = [];

    // Step 1: Create Conversation
    debugPrint('OmiSyncService: Creating conversation...');
    final conversationResult = await OmiApi.createConversation(
      title: _generateConversationTitle(transcript),
      language: detectedLanguage,
      metadata: {
        'transcript': transcript,
        'created_at': DateTime.now().toIso8601String(),
        'source': 'flutter_app',
        'detected_language': detectedLanguage,
      },
    );

    if (conversationResult.isSuccess && conversationResult.data != null) {
      conversationId = conversationResult.data!.id;
      debugPrint('Created Omi conversation: ${conversationResult.data!.toJson()}');
    } else {
      debugPrint('Failed to create conversation: ${conversationResult.error}');
    }

    // Step 2: Create Memory
    debugPrint('OmiSyncService: Creating memory...');
    final memory = OmiMemory(
      id: _uuid.v4(),
      type: _detectMemoryType(transcript),
      content: _generateMemoryContent(transcript),
      datetimeRaw: _extractDatetime(transcript),
      importance: _detectImportance(transcript),
      createdAt: DateTime.now(),
      language: _detectLanguage(transcript),
      metadata: {
        'conversation_id': conversationId,
        'source': 'flutter_app',
      },
    );

    final memoryResult = await OmiApi.createMemory(memory);

    if (memoryResult.isSuccess && memoryResult.data != null) {
      memoryId = memoryResult.data!.id;
      debugPrint('Created Omi memory: ${memoryResult.data!.toJson()}');
    } else {
      debugPrint('Failed to create memory: ${memoryResult.error}');
    }

    // Step 3: Extract and create Action Items
    debugPrint('OmiSyncService: Extracting action items...');
    final actionItems = _extractActionItems(transcript, detectedLanguage);
    
    for (final item in actionItems) {
      debugPrint('OmiSyncService: Creating action item: ${item.title}');
      final actionResult = await OmiApi.createActionItem(item);
      
      if (actionResult.isSuccess && actionResult.data != null) {
        actionItemIds.add(actionResult.data!.id);
        debugPrint('Created Omi action item: ${actionResult.data!.toJson()}');
      } else {
        debugPrint('Failed to create action item: ${actionResult.error}');
      }
    }

    // Step 4: Verify and log results
    await _verifyAndLogResults(conversationId, memoryId, actionItemIds);

    return OmiSyncResult(
      conversationId: conversationId,
      memoryId: memoryId,
      actionItemIds: actionItemIds,
      success: conversationId != null || memoryId != null,
    );
  }

  String _generateConversationTitle(String transcript) {
    final lower = transcript.toLowerCase();
    
    if (lower.contains('meeting') || lower.contains('standup') || lower.contains('stand-up')) {
      return 'Meeting';
    }
    if (lower.contains('project') || lower.contains('feature') || lower.contains('deploy') || lower.contains('bug')) {
      return 'Project Discussion';
    }
    if (lower.contains('task') || lower.contains('todo') || lower.contains('to-do')) {
      return 'Task Planning';
    }
    if (lower.contains('remind') || lower.contains('reminder')) {
      return 'Reminder';
    }
    if (lower.length > 50) {
      return transcript.substring(0, 50).trim() + (transcript.length > 50 ? '...' : '');
    }
    return 'Voice Note';
  }

  String _detectMemoryType(String transcript) {
    final lower = transcript.toLowerCase();
    
    if (lower.contains('remember') || lower.contains('my favourite') || 
        lower.contains('my favorite') || lower.contains('important')) {
      return 'fact';
    }
    if (lower.contains('meeting') || lower.contains('appointment') || 
        lower.contains('schedule') || lower.contains('tomorrow') || lower.contains('next')) {
      return 'event';
    }
    if (lower.contains('need to') || lower.contains('have to') || 
        lower.contains('must') || lower.contains('should') || lower.contains('task')) {
      return 'task';
    }
    if (lower.contains('remind') || lower.contains('reminder')) {
      return 'reminder';
    }
    return 'note';
  }

  String _generateMemoryContent(String transcript) {
    final lower = transcript.toLowerCase();
    
    // Summarize if too long
    if (transcript.length > 200) {
      final sentences = transcript.split(RegExp(r'[.!?]'));
      if (sentences.length > 1) {
        return sentences.first.trim() + '.';
      }
      return transcript.substring(0, 200).trim() + '...';
    }
    return transcript;
  }

  String? _extractDatetime(String transcript) {
    final lower = transcript.toLowerCase();
    
    // Check for tomorrow
    if (lower.contains('tomorrow')) {
      final timeMatch = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', caseSensitive: false).firstMatch(transcript);
      if (timeMatch != null) {
        final hour = int.tryParse(timeMatch.group(1) ?? '9') ?? 9;
        final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
        final isPm = timeMatch.group(3)?.toLowerCase() == 'pm';
        final actualHour = isPm && hour < 12 ? hour + 12 : hour;
        
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, actualHour, minute).toIso8601String();
      }
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0).toIso8601String();
    }
    
    // Check for today
    if (lower.contains('today')) {
      final timeMatch = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', caseSensitive: false).firstMatch(transcript);
      if (timeMatch != null) {
        final hour = int.tryParse(timeMatch.group(1) ?? '9') ?? 9;
        final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
        final isPm = timeMatch.group(3)?.toLowerCase() == 'pm';
        final actualHour = isPm && hour < 12 ? hour + 12 : hour;
        
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, actualHour, minute).toIso8601String();
      }
    }
    
    return null;
  }

  int _detectImportance(String transcript) {
    final lower = transcript.toLowerCase();
    
    if (lower.contains('urgent') || lower.contains('important') || lower.contains('asap')) {
      return 5;
    }
    if (lower.contains('tomorrow') || lower.contains('today') || lower.contains('deadline')) {
      return 4;
    }
    if (lower.contains('this week') || lower.contains('soon')) {
      return 3;
    }
    return 3;
  }

  String? _detectLanguage(String transcript) {
    debugPrint('OmiSyncService: === LANGUAGE DETECTION ===');
    debugPrint('OmiSyncService: Transcript: "$transcript"');
    
    // Check for native script characters first (strongest signal)
    if (_containsDevanagariScript(transcript)) {
      debugPrint('OmiSyncService: Detected Devanagari script - Hindi');
      return 'hi';
    }
    
    if (_containsGujaratiScript(transcript)) {
      debugPrint('OmiSyncService: Detected Gujarati script - Gujarati');
      return 'gu';
    }
    
    final lower = transcript.toLowerCase();
    
    // STRONG Hindi words - distinctive Hindi words only
    // These words are distinctly Hindi and rarely appear in English
    final strongHindiWords = [
      // Strong time words
      'kal', 'parso', 'aaj', 'subah', 'shaam', 'raat', 'din', 'rat', 'pahle', 'baad',
      // Strong verbs
      'karna', 'hona', 'lena', 'dena', 'jaana', 'aana', 'dekhna', 'sunna', 'bolna',
      // Strong common words
      'kya', 'kaun', 'kaise', 'kaha', 'kab', 'kyu', 'nahi', 'haan', 'han',
      // Strong pronouns
      'main', 'mujhe', 'tumhe', 'ham', 'tum', 'apna', 'mera', 'tumhara',
      // Strong action words
      'chalo', 'jaldi', 'dekho', 'suno', 'karo', 'lena', 'dena', 'banao',
      // Strong nouns
      'yaad', 'bat', 'kaam', 'paisa', 'ghar', 'log', 'desh',
    ];
    
    // STRONG Gujarati words - distinctive Gujarati words only
    final strongGujaratiWords = [
      // Strong time words
      'malg', 'maalag', 'pachhi', 'pella', 'dine', 'raat', 'sanj', 'aj', 'aaj',
      // Strong verbs
      'karvo', 'thavu', 'lovo', 'dovo', 'javu', 'aavu', 'vakhvu', 'sunvu',
      // Strong common words
      'kay', 'su', 'kem', 'kevi', 'nai', 'na', 'haan', 'pan', 'chhe',
      // Strong pronouns
      'hu', 'tame', 'amhe', 'majhe', 'mari', 'mare', 'tamari', 'tamre', 'amari',
      // Strong action words
      'chalo', 'jaldi', 'banao', 'kare', 'lovo', 'dovo', 'cho',
      // Strong nouns
      'kaam', 'paiso', 'ghar', 'lok', 'desh', 'vichar', 'yaad',
    ];
    
    // Check for strong Hindi words with word boundary matching
    int hindiScore = 0;
    final hindiMatches = <String>[];
    for (final word in strongHindiWords) {
      if (_containsWord(lower, word)) {
        hindiMatches.add(word);
        hindiScore++;
      }
    }
    
    // Check for strong Gujarati words
    int gujaratiScore = 0;
    final gujaratiMatches = <String>[];
    for (final word in strongGujaratiWords) {
      if (_containsWord(lower, word)) {
        gujaratiMatches.add(word);
        gujaratiScore++;
      }
    }
    
    debugPrint('OmiSyncService: Hindi matches: $hindiMatches (score: $hindiScore)');
    debugPrint('OmiSyncService: Gujarati matches: $gujaratiMatches (score: $gujaratiScore)');
    
    // Only detect Hindi/Gujarati if we have at least 2 strong distinctive words
    // AND the matches don't overlap significantly with English
    final englishOverlap = _countEnglishOverlap(lower);
    
    if (hindiScore >= 2 && hindiScore > englishOverlap) {
      debugPrint('OmiSyncService: Detected HINDI (score: $hindiScore, English overlap: $englishOverlap)');
      return 'hi';
    }
    
    if (gujaratiScore >= 2 && gujaratiScore > englishOverlap) {
      debugPrint('OmiSyncService: Detected GUJARATI (score: $gujaratiScore, English overlap: $englishOverlap)');
      return 'gu';
    }
    
    // Default to English
    debugPrint('OmiSyncService: Detected ENGLISH (Hindi: $hindiScore, Gujarati: $gujaratiScore, English overlap: $englishOverlap)');
    return 'en';
  }
  
  bool _containsDevanagariScript(String text) {
    // Devanagari Unicode range: U+0900 - U+097F
    final devanagariPattern = RegExp(r'[\u0900-\u097F]');
    return devanagariPattern.hasMatch(text);
  }
  
  bool _containsGujaratiScript(String text) {
    // Gujarati Unicode range: U+0A80 - U+0AFF
    final gujaratiPattern = RegExp(r'[\u0A80-\u0AFF]');
    return gujaratiPattern.hasMatch(text);
  }
  
  int _countEnglishOverlap(String text) {
    // Count common English words that might overlap
    final englishOverlapWords = ['to', 'the', 'a', 'an', 'is', 'are', 'was', 'were', 'in', 'on', 'at', 'for', 'of', 'and', 'or', 'but'];
    int count = 0;
    for (final word in englishOverlapWords) {
      if (_containsWord(text, word)) {
        count++;
      }
    }
    return count;
  }
  
  bool _containsWord(String text, String word) {
    final escapedWord = RegExp.escape(word);
    final pattern = RegExp('(?:^|[^a-zA-Z])$escapedWord(?:[^a-zA-Z]|\$)', caseSensitive: false);
    return pattern.hasMatch(text);
  }

  List<OmiActionItem> _extractActionItems(String transcript, String language) {
    final List<OmiActionItem> items = [];
    final lower = transcript.toLowerCase();
    
    debugPrint('OmiSyncService: Extracting action items with language: $language');
    
    // English patterns
    if (language == 'en' || language == null) {
      debugPrint('OmiSyncService: Using English action item patterns');
      
      // Pattern: "reminder to [action]" or "set a reminder to [action]"
      final reminderPattern = RegExp(r'(?:set\s+a\s+)?reminder\s+(?:to\s+)?(.+?)(?:\.|$)', caseSensitive: false);
      final reminderMatches = reminderPattern.allMatches(transcript);
      for (final match in reminderMatches) {
        final task = match.group(1)?.trim();
        if (task != null && task.length > 2) {
          debugPrint('OmiSyncService: Found English reminder action item: "$task"');
          items.add(OmiActionItem(
            id: _uuid.v4(),
            title: _capitalizeFirst(task),
            description: 'Extracted from voice transcript',
            dueDate: _extractDueDate(transcript, language),
            completed: false,
            isRecurring: false,
            createdAt: DateTime.now(),
            language: language,
          ));
        }
      }
      
      // Pattern: "need to", "have to", "must", "should", "gotta"
      final needToPattern = RegExp(r'(?:i\s+)?(?:need to|have to|must|should|gotta)\s+(.+?)(?:\.|$)', caseSensitive: false);
      final needToMatches = needToPattern.allMatches(transcript);
      for (final match in needToMatches) {
        final task = match.group(1)?.trim();
        if (task != null && task.length > 2 && !items.any((i) => i.title.toLowerCase().contains(task.toLowerCase()))) {
          debugPrint('OmiSyncService: Found English need-to action item: "$task"');
          items.add(OmiActionItem(
            id: _uuid.v4(),
            title: _capitalizeFirst(task),
            description: 'Extracted from voice transcript',
            dueDate: _extractDueDate(transcript, language),
            completed: false,
            isRecurring: false,
            createdAt: DateTime.now(),
            language: language,
          ));
        }
      }
      
      // Pattern: "complete the", "fix the", "deploy the", etc.
      final actionPattern = RegExp(r'(?:complete|fix|deploy|build|create|finish|update|add|remove|implement)\s+the\s+(.+?)(?:\.|$)', caseSensitive: false);
      final actionMatches = actionPattern.allMatches(transcript);
      for (final match in actionMatches) {
        final task = match.group(1)?.trim();
        if (task != null && task.length > 2 && !items.any((i) => i.title.toLowerCase().contains(task.toLowerCase()))) {
          debugPrint('OmiSyncService: Found English action pattern: $task');
          items.add(OmiActionItem(
            id: _uuid.v4(),
            title: _capitalizeFirst(task),
            description: 'Extracted from voice transcript',
            dueDate: _extractDueDate(transcript, language),
            completed: false,
            isRecurring: false,
            createdAt: DateTime.now(),
            language: language,
          ));
        }
      }
      
      final byTimePattern = RegExp(r'(?:by|before)\s+(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\s*(?:tomorrow|today)?', caseSensitive: false);
      final byTimeMatch = byTimePattern.firstMatch(transcript);
      if (byTimeMatch != null && items.isEmpty) {
        final sentences = transcript.split(RegExp(r'[.!?]'));
        if (sentences.isNotEmpty) {
          final firstSentence = sentences.first.trim();
          if (firstSentence.length > 5) {
            debugPrint('OmiSyncService: Found task with English deadline: $firstSentence');
            items.add(OmiActionItem(
              id: _uuid.v4(),
              title: _capitalizeFirst(firstSentence),
              description: 'Task with deadline: ${byTimeMatch.group(1)}',
              dueDate: _extractDueDate(transcript, language),
              completed: false,
              isRecurring: false,
              createdAt: DateTime.now(),
              language: language,
            ));
          }
        }
      }
    }
    
    // Hindi patterns
    if (language == 'hi') {
      debugPrint('OmiSyncService: Using Hindi action item patterns');
      
      final karnaHaiPattern = RegExp(r'(?:mujhe|main|humein|hum)\s+(?:karna|karana|karne)\s+(?:hai|hain)\s*(.+?)(?:\.|$)', caseSensitive: false);
      final karnaMatches = karnaHaiPattern.allMatches(transcript);
      for (final match in karnaMatches) {
        final task = match.group(1)?.trim();
        if (task != null && task.length > 2) {
          debugPrint('OmiSyncService: Found Hindi action item: $task');
          items.add(OmiActionItem(
            id: _uuid.v4(),
            title: _capitalizeFirst(task),
            description: 'Hindi se extract kiya gaya',
            dueDate: _extractDueDate(transcript, language),
            completed: false,
            isRecurring: false,
            createdAt: DateTime.now(),
            language: language,
          ));
        }
      }
      
      final karoPattern = RegExp(r'(?:(?:ye|is)(?:\s+kaam)?\s+)?(?:kar\s*lena|kar\s*dena|kar\s*unga|kar\s*ungi)\s*(.+?)?(?:\.|$)', caseSensitive: false);
      final karoMatches = karoPattern.allMatches(transcript);
      for (final match in karoMatches) {
        final task = match.group(1)?.trim();
        if (task != null && task.length > 2 && !items.any((i) => i.title.toLowerCase().contains(task.toLowerCase()))) {
          debugPrint('OmiSyncService: Found Hindi karo pattern: $task');
          items.add(OmiActionItem(
            id: _uuid.v4(),
            title: _capitalizeFirst(task ?? match.group(0) ?? ''),
            description: 'Hindi se extract kiya gaya',
            dueDate: _extractDueDate(transcript, language),
            completed: false,
            isRecurring: false,
            createdAt: DateTime.now(),
            language: language,
          ));
        }
      }
      
      final completeKarnaPattern = RegExp(r'(?:finish|complete|khatam|poora)\s+(?:karna|kar)\s+(?:the|the\s+)?(.+?)(?:\.|$)', caseSensitive: false);
      final completeMatches = completeKarnaPattern.allMatches(transcript);
      for (final match in completeMatches) {
        final task = match.group(1)?.trim();
        if (task != null && task.length > 2 && !items.any((i) => i.title.toLowerCase().contains(task.toLowerCase()))) {
          debugPrint('OmiSyncService: Found Hindi complete pattern: $task');
          items.add(OmiActionItem(
            id: _uuid.v4(),
            title: _capitalizeFirst(task),
            description: 'Hindi se extract kiya gaya',
            dueDate: _extractDueDate(transcript, language),
            completed: false,
            isRecurring: false,
            createdAt: DateTime.now(),
            language: language,
          ));
        }
      }
    }
    
    // Gujarati patterns
    if (language == 'gu') {
      debugPrint('OmiSyncService: Using Gujarati action item patterns');
      
      final karvaniChePattern = RegExp(r'(?:mujje|main|humnje|ham)\s+(?:karvani|karvana|karvane)\s+(?:che|chhe)\s*(.+?)(?:\.|$)', caseSensitive: false);
      final karvaniMatches = karvaniChePattern.allMatches(transcript);
      for (final match in karvaniMatches) {
        final task = match.group(1)?.trim();
        if (task != null && task.length > 2) {
          debugPrint('OmiSyncService: Found Gujarati action item: $task');
          items.add(OmiActionItem(
            id: _uuid.v4(),
            title: _capitalizeFirst(task),
            description: 'Gujarati thi extract thayo',
            dueDate: _extractDueDate(transcript, language),
            completed: false,
            isRecurring: false,
            createdAt: DateTime.now(),
            language: language,
          ));
        }
      }
      
      final karoNePattern = RegExp(r'(?:(?:aa|ene)\s+kaam)?\s+(?:kar\s*lene|kar\s*dene|kar\s*su|kar\s*she)\s*(.+?)?(?:\.|$)', caseSensitive: false);
      final karoNeMatches = karoNePattern.allMatches(transcript);
      for (final match in karoNeMatches) {
        final task = match.group(1)?.trim();
        if (task != null && task.length > 2 && !items.any((i) => i.title.toLowerCase().contains(task.toLowerCase()))) {
          debugPrint('OmiSyncService: Found Gujarati karo pattern: $task');
          items.add(OmiActionItem(
            id: _uuid.v4(),
            title: _capitalizeFirst(task ?? match.group(0) ?? ''),
            description: 'Gujarati thi extract thayo',
            dueDate: _extractDueDate(transcript, language),
            completed: false,
            isRecurring: false,
            createdAt: DateTime.now(),
            language: language,
          ));
        }
      }
      
      final purnKariPattern = RegExp(r'(?:finish|complete|purn|poorn)\s+(?:kare|kari|karsho)\s+(?:anje|chhe)?(.+?)(?:\.|$)', caseSensitive: false);
      final purnMatches = purnKariPattern.allMatches(transcript);
      for (final match in purnMatches) {
        final task = match.group(1)?.trim();
        if (task != null && task.length > 2 && !items.any((i) => i.title.toLowerCase().contains(task.toLowerCase()))) {
          debugPrint('OmiSyncService: Found Gujarati complete pattern: $task');
          items.add(OmiActionItem(
            id: _uuid.v4(),
            title: _capitalizeFirst(task),
            description: 'Gujarati thi extract thayo',
            dueDate: _extractDueDate(transcript, language),
            completed: false,
            isRecurring: false,
            createdAt: DateTime.now(),
            language: language,
          ));
        }
      }
    }
    
    debugPrint('OmiSyncService: Total action items extracted: ${items.length}');
    return items;
  }

  DateTime? _extractDueDate(String transcript, String language) {
    final lower = transcript.toLowerCase();
    final now = DateTime.now();
    
    debugPrint('OmiSyncService: Extracting due date with language: $language');
    
    // English patterns
    if (language == 'en' || language == null) {
      if (lower.contains('tomorrow')) {
        final tomorrow = now.add(const Duration(days: 1));
        final timeMatch = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', caseSensitive: false).firstMatch(transcript);
        if (timeMatch != null) {
          final hour = int.tryParse(timeMatch.group(1) ?? '9') ?? 9;
          final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
          final isPm = timeMatch.group(3)?.toLowerCase() == 'pm';
          final actualHour = isPm && hour < 12 ? hour + 12 : hour;
          debugPrint('OmiSyncService: Found English tomorrow at $actualHour:$minute');
          return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, actualHour, minute);
        }
        debugPrint('OmiSyncService: Found English tomorrow (default time)');
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18, 0);
      }
      
      if (lower.contains('today')) {
        final timeMatch = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', caseSensitive: false).firstMatch(transcript);
        if (timeMatch != null) {
          final hour = int.tryParse(timeMatch.group(1) ?? '9') ?? 9;
          final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
          final isPm = timeMatch.group(3)?.toLowerCase() == 'pm';
          final actualHour = isPm && hour < 12 ? hour + 12 : hour;
          debugPrint('OmiSyncService: Found English today at $actualHour:$minute');
          return DateTime(now.year, now.month, now.day, actualHour, minute);
        }
        debugPrint('OmiSyncService: Found English today (default time)');
        return DateTime(now.year, now.month, now.day, 18, 0);
      }
    }
    
    // Hindi patterns
    if (language == 'hi') {
      debugPrint('OmiSyncService: Using Hindi due date patterns');
      
      // Kal = tomorrow
      if (lower.contains('kal')) {
        final tomorrow = now.add(const Duration(days: 1));
        final timeMatch = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(?:baje|vaje|bajkar)?', caseSensitive: false).firstMatch(transcript);
        if (timeMatch != null) {
          final hour = int.tryParse(timeMatch.group(1) ?? '9') ?? 9;
          final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
          debugPrint('OmiSyncService: Found Hindi kal at $hour:$minute');
          return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
        }
        debugPrint('OmiSyncService: Found Hindi kal (default time)');
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18, 0);
      }
      
      // Aaj = today
      if (lower.contains('aaj') || lower.contains('aj')) {
        final timeMatch = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(?:baje|vaje)?', caseSensitive: false).firstMatch(transcript);
        if (timeMatch != null) {
          final hour = int.tryParse(timeMatch.group(1) ?? '9') ?? 9;
          final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
          debugPrint('OmiSyncService: Found Hindi aaj at $hour:$minute');
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
        debugPrint('OmiSyncService: Found Hindi aaj (default time)');
        return DateTime(now.year, now.month, now.day, 18, 0);
      }
      
      // In X hours/minutes
      final inMinutesMatch = RegExp(r'(\d+)\s*(?:minute|min)\s*(?:mein|me)?', caseSensitive: false).firstMatch(transcript);
      if (inMinutesMatch != null) {
        final minutes = int.tryParse(inMinutesMatch.group(1) ?? '0') ?? 0;
        debugPrint('OmiSyncService: Found Hindi $minutes minutes');
        return now.add(Duration(minutes: minutes));
      }
      
      final inHoursMatch = RegExp(r'(\d+)\s*(?:ghanta|ghante|hour)\s*(?:mein|me)?', caseSensitive: false).firstMatch(transcript);
      if (inHoursMatch != null) {
        final hours = int.tryParse(inHoursMatch.group(1) ?? '0') ?? 0;
        debugPrint('OmiSyncService: Found Hindi $hours hours');
        return now.add(Duration(hours: hours));
      }
    }
    
    // Gujarati patterns
    if (language == 'gu') {
      debugPrint('OmiSyncService: Using Gujarati due date patterns');
      
      // Malg = tomorrow (tomorrow in Gujarati)
      if (lower.contains('malg') || lower.contains('maalag')) {
        final tomorrow = now.add(const Duration(days: 1));
        final timeMatch = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(?:vaje|bije)?', caseSensitive: false).firstMatch(transcript);
        if (timeMatch != null) {
          final hour = int.tryParse(timeMatch.group(1) ?? '9') ?? 9;
          final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
          debugPrint('OmiSyncService: Found Gujarati malg at $hour:$minute');
          return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
        }
        debugPrint('OmiSyncService: Found Gujarati malg (default time)');
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18, 0);
      }
      
      // Aj = today
      if (lower.contains('aj') || lower.contains('aaj')) {
        final timeMatch = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(?:vaje)?', caseSensitive: false).firstMatch(transcript);
        if (timeMatch != null) {
          final hour = int.tryParse(timeMatch.group(1) ?? '9') ?? 9;
          final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
          debugPrint('OmiSyncService: Found Gujarati aj at $hour:$minute');
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
        debugPrint('OmiSyncService: Found Gujarati aj (default time)');
        return DateTime(now.year, now.month, now.day, 18, 0);
      }
      
      // In X minutes/hours
      final inMinutesMatch = RegExp(r'(\d+)\s*(?:minute|min|minuto)\s*(?:ma|mae|me)?', caseSensitive: false).firstMatch(transcript);
      if (inMinutesMatch != null) {
        final minutes = int.tryParse(inMinutesMatch.group(1) ?? '0') ?? 0;
        debugPrint('OmiSyncService: Found Gujarati $minutes minutes');
        return now.add(Duration(minutes: minutes));
      }
      
      final inHoursMatch = RegExp(r'(\d+)\s*(?:ghanta|hour|tairo)\s*(?:ma|mae|me)?', caseSensitive: false).firstMatch(transcript);
      if (inHoursMatch != null) {
        final hours = int.tryParse(inHoursMatch.group(1) ?? '0') ?? 0;
        debugPrint('OmiSyncService: Found Gujarati $hours hours');
        return now.add(Duration(hours: hours));
      }
    }
    
    return null;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _verifyAndLogResults(String? conversationId, String? memoryId, List<String> actionItemIds) async {
    debugPrint('OmiSyncService: Verifying created entities...');
    
    // Verify conversations
    final convResult = await OmiApi.getConversations(limit: 5);
    if (convResult.isSuccess) {
      debugPrint('OmiSyncService: GET /conversations - Found ${convResult.data?.length ?? 0} conversations');
      if (conversationId != null && convResult.data != null) {
        final found = convResult.data!.any((c) => c.id == conversationId);
        debugPrint('OmiSyncService: Conversation "$conversationId" exists in API: $found');
      }
    } else {
      debugPrint('OmiSyncService: Failed to verify conversations: ${convResult.error}');
    }
    
    // Verify memories
    final memResult = await OmiApi.getMemories(limit: 5);
    if (memResult.isSuccess) {
      debugPrint('OmiSyncService: GET /memories - Found ${memResult.data?.length ?? 0} memories');
      if (memoryId != null && memResult.data != null) {
        final found = memResult.data!.any((m) => m.id == memoryId);
        debugPrint('OmiSyncService: Memory "$memoryId" exists in API: $found');
      }
    } else {
      debugPrint('OmiSyncService: Failed to verify memories: ${memResult.error}');
    }
    
    // Verify action items
    final actionResult = await OmiApi.getActionItems(limit: 5);
    if (actionResult.isSuccess) {
      debugPrint('OmiSyncService: GET /action-items - Found ${actionResult.data?.length ?? 0} action items');
      for (final id in actionItemIds) {
        if (actionResult.data != null) {
          final found = actionResult.data!.any((a) => a.id == id);
          debugPrint('OmiSyncService: Action item "$id" exists in API: $found');
        }
      }
    } else {
      debugPrint('OmiSyncService: Failed to verify action items: ${actionResult.error}');
    }
  }
}

class OmiSyncResult {
  final String? conversationId;
  final String? memoryId;
  final List<String> actionItemIds;
  final bool success;

  const OmiSyncResult({
    this.conversationId,
    this.memoryId,
    this.actionItemIds = const [],
    this.success = false,
  });
}

final omiSyncServiceProvider = Provider<OmiSyncService>((ref) => OmiSyncService.instance);