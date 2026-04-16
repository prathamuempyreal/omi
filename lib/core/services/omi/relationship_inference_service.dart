import 'package:flutter/foundation.dart';
import '../../../data/models/api/omi_models.dart';

class RelationshipInferenceService {
  RelationshipInferenceService._();

  static RelationshipInferenceService? _instance;
  static RelationshipInferenceService get instance =>
      _instance ??= RelationshipInferenceService._();

  final Map<String, InferredRelationship> _inferredRelationships = {};

  List<String> extractNames(String text) {
    final names = <String>[];
    
    final patterns = [
      RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\b'),
      RegExp(r'(?:my|our|with)\s+([A-Z][a-z]+)'),
      RegExp(r'called\s+([A-Z][a-z]+)'),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final name = match.group(1)?.trim();
        if (name != null && name.length > 2 && name.length < 30) {
          if (!_isCommonWord(name)) {
            names.add(name);
          }
        }
      }
    }

    debugPrint('RelationshipInference: Extracted names: $names');
    return names.toSet().toList();
  }

  bool _isCommonWord(String word) {
    final commonWords = {
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
      'january', 'february', 'march', 'april', 'may', 'june', 'july', 'august',
      'september', 'october', 'november', 'december',
      'morning', 'afternoon', 'evening', 'night',
      'hello', 'thanks', 'please', 'sorry',
      'meeting', 'project', 'deadline', 'reminder',
      'kya', 'kaun', 'aaj', 'kal',
      'kay', 'su', 'aj', 'malg',
    };
    
    return commonWords.contains(word.toLowerCase());
  }

  InferredRelationship inferRelationship(String name, List<String> conversationContexts) {
    debugPrint('RelationshipInference: Inferring relationship for: $name');

    final combinedText = conversationContexts.join(' ').toLowerCase();
    
    int friendScore = 0;
    int managerScore = 0;
    int clientScore = 0;
    int familyScore = 0;
    int colleagueScore = 0;

    final friendIndicators = [
      'friend', 'bestie', 'bff', 'pal', 'buddy', 'chill',
      'hang out', 'party', 'weekend', 'fun',
      'dost', 'saheli', 'yaar', 'bhai', 'behen',
    ];

    final managerIndicators = [
      'manager', 'boss', 'lead', 'supervisor', 'ceo', 'director',
      'reports to', 'meeting with', 'deadline', 'task from',
      'performance', 'review', 'one on one',
      'manager', 'sir', 'madam',
    ];

    final clientIndicators = [
      'client', 'customer', 'buyer', 'contract',
      'proposal', 'deal', 'sale', 'business',
      'meeting with', 'presentation', 'demo',
      'client', 'customer', 'vakta',
    ];

    final familyIndicators = [
      'mom', 'dad', 'mother', 'father', 'sister', 'brother',
      'wife', 'husband', 'son', 'daughter', 'family',
      'maa', 'papa', 'bhai', 'behen', 'dost',
      'khand', 'vahini', 'bhabhi',
    ];

    final colleagueIndicators = [
      'colleague', 'coworker', 'team', 'team member',
      'office', 'work', 'project together',
      'colleague', 'partner', 'associate',
    ];

    for (final indicator in friendIndicators) {
      if (combinedText.contains(indicator)) friendScore++;
    }

    for (final indicator in managerIndicators) {
      if (combinedText.contains(indicator)) managerScore += 2;
    }

    for (final indicator in clientIndicators) {
      if (combinedText.contains(indicator)) clientScore += 2;
    }

    for (final indicator in familyIndicators) {
      if (combinedText.contains(indicator)) familyScore += 2;
    }

    for (final indicator in colleagueIndicators) {
      if (combinedText.contains(indicator)) colleagueScore++;
    }

    String inferredType;
    int confidence;

    final scores = {
      'friend': friendScore,
      'manager': managerScore,
      'client': clientScore,
      'family': familyScore,
      'colleague': colleagueScore,
    };

    final maxEntry = scores.entries.reduce((a, b) => a.value > b.value ? a : b);

    if (maxEntry.value == 0) {
      inferredType = 'unknown';
      confidence = 0;
    } else {
      inferredType = maxEntry.key;
      confidence = (maxEntry.value * 20).clamp(20, 100);
    }

    final relationship = InferredRelationship(
      name: name,
      type: inferredType,
      confidence: confidence,
      lastMentioned: DateTime.now(),
      mentionCount: conversationContexts.length,
    );

    _inferredRelationships[name] = relationship;
    debugPrint('RelationshipInference: Inferred $name as $inferredType (confidence: $confidence%)');

    return relationship;
  }

  InferredRelationship? getRelationship(String name) {
    return _inferredRelationships[name];
  }

  List<InferredRelationship> getAllRelationships() {
    return _inferredRelationships.values.toList()
      ..sort((a, b) => b.mentionCount.compareTo(a.mentionCount));
  }

  List<InferredRelationship> getRelationshipsByType(String type) {
    return _inferredRelationships.values
        .where((r) => r.type == type)
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  void processConversations(List<OmiConversation> conversations) {
    debugPrint('RelationshipInference: Processing ${conversations.length} conversations');

    final nameOccurrences = <String, List<String>>{};

    for (final conv in conversations) {
      final names = extractNames(conv.transcript ?? '');
      for (final name in names) {
        nameOccurrences.putIfAbsent(name, () => []).add(conv.transcript ?? '');
      }
    }

    for (final entry in nameOccurrences.entries) {
      if (entry.value.length >= 2) {
        inferRelationship(entry.key, entry.value);
      }
    }

    debugPrint('RelationshipInference: Found ${_inferredRelationships.length} inferred relationships');
  }

  void clearRelationships() {
    _inferredRelationships.clear();
    debugPrint('RelationshipInference: Cleared all relationships');
  }
}

class InferredRelationship {
  final String name;
  final String type;
  final int confidence;
  final DateTime lastMentioned;
  final int mentionCount;

  InferredRelationship({
    required this.name,
    required this.type,
    required this.confidence,
    required this.lastMentioned,
    required this.mentionCount,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'confidence': confidence,
    'last_mentioned': lastMentioned.toIso8601String(),
    'mention_count': mentionCount,
  };

  factory InferredRelationship.fromJson(Map<String, dynamic> json) {
    return InferredRelationship(
      name: json['name'] as String,
      type: json['type'] as String,
      confidence: json['confidence'] as int,
      lastMentioned: DateTime.parse(json['last_mentioned'] as String),
      mentionCount: json['mention_count'] as int,
    );
  }
}
