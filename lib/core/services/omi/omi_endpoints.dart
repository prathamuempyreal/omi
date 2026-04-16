import 'omi_api_service.dart';
import '../../../data/models/api/omi_models.dart';

class OmiEndpoints {
  OmiEndpoints._();

  static const String conversations = '/conversations';
  static const String memories = '/memories';
  static const String actionItems = '/action-items';
  static const String dailySummary = '/daily-summary';
  static const String reflections = '/reflections';
  static const String goals = '/goals';
  static const String transcripts = '/transcripts';
  static const String settings = '/settings';
  static const String mcpConfig = '/mcp/config';
}

class OmiApi {
  OmiApi._();

  static final OmiApiService _api = OmiApiService.instance;

  static Future<ApiResponse<List<OmiConversation>>> getConversations({
    int? limit,
    int? offset,
  }) async {
    final response = await _api.get<List<OmiConversation>>(
      OmiEndpoints.conversations,
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
      parser: (data) {
        if (data is List) {
          return data.map((e) => OmiConversation.fromJson(e)).toList();
        }
        return [];
      },
    );
    return response;
  }

  static Future<ApiResponse<OmiConversation>> getConversation(String id) async {
    final response = await _api.get<OmiConversation>(
      '${OmiEndpoints.conversations}/$id',
      parser: (data) => OmiConversation.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<OmiConversation>> createConversation({
    String? title,
    String? language,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _api.post<OmiConversation>(
      OmiEndpoints.conversations,
      data: {
        if (title != null) 'title': title,
        if (language != null) 'language': language,
        if (metadata != null) 'metadata': metadata,
      },
      parser: (data) => OmiConversation.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<OmiConversation>> updateConversation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put<OmiConversation>(
      '${OmiEndpoints.conversations}/$id',
      data: data,
      parser: (data) => OmiConversation.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<void>> deleteConversation(String id) async {
    return await _api.delete('${OmiEndpoints.conversations}/$id');
  }

  static Future<ApiResponse<List<OmiMemory>>> getMemories({
    String? type,
    int? limit,
    int? offset,
  }) async {
    final response = await _api.get<List<OmiMemory>>(
      OmiEndpoints.memories,
      queryParameters: {
        if (type != null) 'type': type,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
      parser: (data) {
        if (data is List) {
          return data.map((e) => OmiMemory.fromJson(e)).toList();
        }
        return [];
      },
    );
    return response;
  }

  static Future<ApiResponse<OmiMemory>> getMemory(String id) async {
    final response = await _api.get<OmiMemory>(
      '${OmiEndpoints.memories}/$id',
      parser: (data) => OmiMemory.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<OmiMemory>> createMemory(OmiMemory memory) async {
    final response = await _api.post<OmiMemory>(
      OmiEndpoints.memories,
      data: memory.toJson(),
      parser: (data) => OmiMemory.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<OmiMemory>> updateMemory(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put<OmiMemory>(
      '${OmiEndpoints.memories}/$id',
      data: data,
      parser: (data) => OmiMemory.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<void>> deleteMemory(String id) async {
    return await _api.delete('${OmiEndpoints.memories}/$id');
  }

  static Future<ApiResponse<List<OmiActionItem>>> getActionItems({
    bool? completed,
    int? limit,
  }) async {
    final response = await _api.get<List<OmiActionItem>>(
      OmiEndpoints.actionItems,
      queryParameters: {
        if (completed != null) 'completed': completed,
        if (limit != null) 'limit': limit,
      },
      parser: (data) {
        if (data is List) {
          return data.map((e) => OmiActionItem.fromJson(e)).toList();
        }
        return [];
      },
    );
    return response;
  }

  static Future<ApiResponse<OmiActionItem>> createActionItem(
    OmiActionItem item,
  ) async {
    final response = await _api.post<OmiActionItem>(
      OmiEndpoints.actionItems,
      data: item.toJson(),
      parser: (data) => OmiActionItem.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<OmiActionItem>> updateActionItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put<OmiActionItem>(
      '${OmiEndpoints.actionItems}/$id',
      data: data,
      parser: (data) => OmiActionItem.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<void>> deleteActionItem(String id) async {
    return await _api.delete('${OmiEndpoints.actionItems}/$id');
  }

  static Future<ApiResponse<OmiDailySummary>> getDailySummary(DateTime date) async {
    final response = await _api.get<OmiDailySummary>(
      OmiEndpoints.dailySummary,
      queryParameters: {'date': date.toIso8601String().split('T')[0]},
      parser: (data) => OmiDailySummary.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<List<OmiReflection>>> getReflections({
    DateTime? date,
    int? limit,
  }) async {
    final response = await _api.get<List<OmiReflection>>(
      OmiEndpoints.reflections,
      queryParameters: {
        if (date != null) 'date': date.toIso8601String().split('T')[0],
        if (limit != null) 'limit': limit,
      },
      parser: (data) {
        if (data is List) {
          return data.map((e) => OmiReflection.fromJson(e)).toList();
        }
        return [];
      },
    );
    return response;
  }

  static Future<ApiResponse<OmiReflection>> createReflection(
    OmiReflection reflection,
  ) async {
    final response = await _api.post<OmiReflection>(
      OmiEndpoints.reflections,
      data: reflection.toJson(),
      parser: (data) => OmiReflection.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<List<OmiGoal>>> getGoals({String? status}) async {
    final response = await _api.get<List<OmiGoal>>(
      OmiEndpoints.goals,
      queryParameters: {
        if (status != null) 'status': status,
      },
      parser: (data) {
        if (data is List) {
          return data.map((e) => OmiGoal.fromJson(e)).toList();
        }
        return [];
      },
    );
    return response;
  }

  static Future<ApiResponse<OmiGoal>> createGoal(OmiGoal goal) async {
    final response = await _api.post<OmiGoal>(
      OmiEndpoints.goals,
      data: goal.toJson(),
      parser: (data) => OmiGoal.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<OmiGoal>> updateGoal(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put<OmiGoal>(
      '${OmiEndpoints.goals}/$id',
      data: data,
      parser: (data) => OmiGoal.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<void>> deleteGoal(String id) async {
    return await _api.delete('${OmiEndpoints.goals}/$id');
  }

  static Future<ApiResponse<OmiTranscript>> getTranscript(String id) async {
    final response = await _api.get<OmiTranscript>(
      '${OmiEndpoints.transcripts}/$id',
      parser: (data) => OmiTranscript.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<OmiSettings>> getSettings() async {
    final response = await _api.get<OmiSettings>(
      OmiEndpoints.settings,
      parser: (data) => OmiSettings.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<OmiSettings>> updateSettings(
    OmiSettings settings,
  ) async {
    final response = await _api.put<OmiSettings>(
      OmiEndpoints.settings,
      data: settings.toJson(),
      parser: (data) => OmiSettings.fromJson(data),
    );
    return response;
  }

  static Future<ApiResponse<OmiMcpConfig>> getMcpConfig() async {
    final response = await _api.get<OmiMcpConfig>(
      OmiEndpoints.mcpConfig,
      parser: (data) => OmiMcpConfig.fromJson(data),
    );
    return response;
  }

  static Future<bool> testConnection() async {
    final response = await _api.get('${OmiEndpoints.conversations}?limit=1');
    return response.isSuccess;
  }
}