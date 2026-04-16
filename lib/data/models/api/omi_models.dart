class OmiConversation {
  final String id;
  final String? title;
  final String? transcript;
  final String? summary;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OmiMessage> messages;
  final String? language;
  final Map<String, dynamic>? metadata;

  OmiConversation({
    required this.id,
    this.title,
    this.transcript,
    this.summary,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
    this.language,
    this.metadata,
  });

  factory OmiConversation.fromJson(Map<String, dynamic> json) {
    return OmiConversation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      transcript: json['transcript']?.toString(),
      summary: json['summary']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString()) 
          : null,
      messages: json['messages'] != null
          ? (json['messages'] as List).map((m) => OmiMessage.fromJson(m)).toList()
          : [],
      language: json['language']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'transcript': transcript,
    'summary': summary,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'language': language,
    'messages': messages.map((m) => m.toJson()).toList(),
    'metadata': metadata,
  };
}

class OmiMessage {
  final String id;
  final String? content;
  final String? role;
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;

  OmiMessage({
    required this.id,
    this.content,
    this.role,
    this.timestamp,
    this.metadata,
  });

  factory OmiMessage.fromJson(Map<String, dynamic> json) {
    return OmiMessage(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString(),
      role: json['role']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'role': role,
    'timestamp': timestamp?.toIso8601String(),
    'metadata': metadata,
  };
}

class OmiMemory {
  final String id;
  final String type;
  final String content;
  final String? datetimeRaw;
  final int importance;
  final DateTime createdAt;
  final String? language;
  final Map<String, dynamic>? metadata;

  OmiMemory({
    required this.id,
    required this.type,
    required this.content,
    this.datetimeRaw,
    required this.importance,
    required this.createdAt,
    this.language,
    this.metadata,
  });

  factory OmiMemory.fromJson(Map<String, dynamic> json) {
    return OmiMemory(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'note',
      content: json['content']?.toString() ?? '',
      datetimeRaw: json['datetime_raw']?.toString(),
      importance: json['importance'] is int 
          ? json['importance'] 
          : int.tryParse(json['importance']?.toString() ?? '3') ?? 3,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      language: json['language']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'content': content,
    'datetime_raw': datetimeRaw,
    'importance': importance,
    'created_at': createdAt.toIso8601String(),
    'language': language,
    'metadata': metadata,
  };
}

class OmiActionItem {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool completed;
  final bool isRecurring;
  final String? recurringPattern;
  final DateTime createdAt;
  final String? conversationId;
  final String? language;
  final Map<String, dynamic>? metadata;

  OmiActionItem({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.completed = false,
    this.isRecurring = false,
    this.recurringPattern,
    required this.createdAt,
    this.conversationId,
    this.language,
    this.metadata,
  });

  factory OmiActionItem.fromJson(Map<String, dynamic> json) {
    return OmiActionItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'].toString()) 
          : null,
      completed: json['completed'] == true || json['completed'] == 'true',
      isRecurring: json['is_recurring'] == true || json['is_recurring'] == 'true',
      recurringPattern: json['recurring_pattern']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      conversationId: json['conversation_id']?.toString(),
      language: json['language']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'due_date': dueDate?.toIso8601String(),
    'completed': completed,
    'is_recurring': isRecurring,
    'recurring_pattern': recurringPattern,
    'created_at': createdAt.toIso8601String(),
    'conversation_id': conversationId,
    'language': language,
    'metadata': metadata,
  };
}

class OmiDailySummary {
  final String id;
  final DateTime date;
  final String? summary;
  final List<String> highlights;
  final int memoriesCount;
  final int conversationsCount;
  final int actionItemsCompleted;
  final int actionItemsPending;
  final Map<String, dynamic>? metadata;

  OmiDailySummary({
    required this.id,
    required this.date,
    this.summary,
    this.highlights = const [],
    this.memoriesCount = 0,
    this.conversationsCount = 0,
    this.actionItemsCompleted = 0,
    this.actionItemsPending = 0,
    this.metadata,
  });

  factory OmiDailySummary.fromJson(Map<String, dynamic> json) {
    return OmiDailySummary(
      id: json['id']?.toString() ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      summary: json['summary']?.toString(),
      highlights: json['highlights'] != null
          ? List<String>.from(json['highlights'])
          : [],
      memoriesCount: json['memories_count'] ?? 0,
      conversationsCount: json['conversations_count'] ?? 0,
      actionItemsCompleted: json['action_items_completed'] ?? 0,
      actionItemsPending: json['action_items_pending'] ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'summary': summary,
    'highlights': highlights,
    'memories_count': memoriesCount,
    'conversations_count': conversationsCount,
    'action_items_completed': actionItemsCompleted,
    'action_items_pending': actionItemsPending,
    'metadata': metadata,
  };
}

class OmiReflection {
  final String id;
  final DateTime date;
  final String? content;
  final String? mood;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  OmiReflection({
    required this.id,
    required this.date,
    this.content,
    this.mood,
    this.tags = const [],
    this.metadata,
  });

  factory OmiReflection.fromJson(Map<String, dynamic> json) {
    return OmiReflection(
      id: json['id']?.toString() ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      content: json['content']?.toString(),
      mood: json['mood']?.toString(),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'content': content,
    'mood': mood,
    'tags': tags,
    'metadata': metadata,
  };
}

class OmiGoal {
  final String id;
  final String title;
  final String? description;
  final String? status;
  final int progress;
  final DateTime? dueDate;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  OmiGoal({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.progress = 0,
    this.dueDate,
    required this.createdAt,
    this.metadata,
  });

  factory OmiGoal.fromJson(Map<String, dynamic> json) {
    return OmiGoal(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      progress: json['progress'] ?? 0,
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'].toString()) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status,
    'progress': progress,
    'due_date': dueDate?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'metadata': metadata,
  };
}

class OmiTranscript {
  final String id;
  final String? content;
  final String? language;
  final double? confidence;
  final List<OmiTranscriptSegment> segments;
  final Map<String, dynamic>? metadata;

  OmiTranscript({
    required this.id,
    this.content,
    this.language,
    this.confidence,
    this.segments = const [],
    this.metadata,
  });

  factory OmiTranscript.fromJson(Map<String, dynamic> json) {
    return OmiTranscript(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString(),
      language: json['language']?.toString(),
      confidence: json['confidence'] is double 
          ? json['confidence'] 
          : double.tryParse(json['confidence']?.toString() ?? '0'),
      segments: json['segments'] != null
          ? (json['segments'] as List).map((s) => OmiTranscriptSegment.fromJson(s)).toList()
          : [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'language': language,
    'confidence': confidence,
    'segments': segments.map((s) => s.toJson()).toList(),
    'metadata': metadata,
  };
}

class OmiTranscriptSegment {
  final int start;
  final int end;
  final String text;
  final String? speaker;

  OmiTranscriptSegment({
    required this.start,
    required this.end,
    required this.text,
    this.speaker,
  });

  factory OmiTranscriptSegment.fromJson(Map<String, dynamic> json) {
    return OmiTranscriptSegment(
      start: json['start'] ?? 0,
      end: json['end'] ?? 0,
      text: json['text']?.toString() ?? '',
      speaker: json['speaker']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'text': text,
    'speaker': speaker,
  };
}

class OmiSettings {
  final bool overviewEvents;
  final bool realtimeTranscript;
  final bool audioBytes;
  final bool daySummary;
  final bool transcriptDiagnostics;
  final bool autoSaveSpeakers;
  final bool relationshipInference;
  final bool goalTracking;
  final bool dailyReflection;

  const OmiSettings({
    this.overviewEvents = true,
    this.realtimeTranscript = true,
    this.audioBytes = false,
    this.daySummary = true,
    this.transcriptDiagnostics = false,
    this.autoSaveSpeakers = true,
    this.relationshipInference = true,
    this.goalTracking = true,
    this.dailyReflection = true,
  });

  factory OmiSettings.fromJson(Map<String, dynamic> json) {
    return OmiSettings(
      overviewEvents: json['overview_events'] ?? true,
      realtimeTranscript: json['realtime_transcript'] ?? true,
      audioBytes: json['audio_bytes'] ?? false,
      daySummary: json['day_summary'] ?? true,
      transcriptDiagnostics: json['transcript_diagnostics'] ?? false,
      autoSaveSpeakers: json['auto_save_speakers'] ?? true,
      relationshipInference: json['relationship_inference'] ?? true,
      goalTracking: json['goal_tracking'] ?? true,
      dailyReflection: json['daily_reflection'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'overview_events': overviewEvents,
    'realtime_transcript': realtimeTranscript,
    'audio_bytes': audioBytes,
    'day_summary': daySummary,
    'transcript_diagnostics': transcriptDiagnostics,
    'auto_save_speakers': autoSaveSpeakers,
    'relationship_inference': relationshipInference,
    'goal_tracking': goalTracking,
    'daily_reflection': dailyReflection,
  };

  OmiSettings copyWith({
    bool? overviewEvents,
    bool? realtimeTranscript,
    bool? audioBytes,
    bool? daySummary,
    bool? transcriptDiagnostics,
    bool? autoSaveSpeakers,
    bool? relationshipInference,
    bool? goalTracking,
    bool? dailyReflection,
  }) {
    return OmiSettings(
      overviewEvents: overviewEvents ?? this.overviewEvents,
      realtimeTranscript: realtimeTranscript ?? this.realtimeTranscript,
      audioBytes: audioBytes ?? this.audioBytes,
      daySummary: daySummary ?? this.daySummary,
      transcriptDiagnostics: transcriptDiagnostics ?? this.transcriptDiagnostics,
      autoSaveSpeakers: autoSaveSpeakers ?? this.autoSaveSpeakers,
      relationshipInference: relationshipInference ?? this.relationshipInference,
      goalTracking: goalTracking ?? this.goalTracking,
      dailyReflection: dailyReflection ?? this.dailyReflection,
    );
  }
}

class OmiMcpConfig {
  final String? serverUrl;
  final bool isConnected;
  final String? apiKeyStatus;
  final DateTime? lastSyncTime;
  final String? syncStatus;

  const OmiMcpConfig({
    this.serverUrl,
    this.isConnected = false,
    this.apiKeyStatus,
    this.lastSyncTime,
    this.syncStatus,
  });

  factory OmiMcpConfig.fromJson(Map<String, dynamic> json) {
    return OmiMcpConfig(
      serverUrl: json['server_url']?.toString(),
      isConnected: json['is_connected'] ?? false,
      apiKeyStatus: json['api_key_status']?.toString(),
      lastSyncTime: json['last_sync_time'] != null 
          ? DateTime.parse(json['last_sync_time'].toString()) 
          : null,
      syncStatus: json['sync_status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'server_url': serverUrl,
    'is_connected': isConnected,
    'api_key_status': apiKeyStatus,
    'last_sync_time': lastSyncTime?.toIso8601String(),
    'sync_status': syncStatus,
  };
}