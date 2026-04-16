import 'package:flutter/foundation.dart';

class MultilingualUIService {
  MultilingualUIService._();

  static MultilingualUIService? _instance;
  static MultilingualUIService get instance =>
      _instance ??= MultilingualUIService._();

  String _currentLanguage = 'en';

  final Map<String, Map<String, String>> _translations = {
    'en': {
      'home': 'Home',
      'memories': 'Memories',
      'reminders': 'Reminders',
      'sessions': 'Sessions',
      'settings': 'Settings',
      'search': 'Search',
      'daily_summary': 'Daily Summary',
      'timeline': 'Timeline',
      'reflection': 'Reflection',
      'goals': 'Goals',
      'ask_omi': 'Ask Omi',
      'what_did_we_discuss': 'What did we discuss about...',
      'tomorrow_reminders': 'Tomorrow reminders',
      'pending_tasks': 'Pending tasks',
      'completed': 'Completed',
      'pending': 'Pending',
      'high_importance': 'High Importance',
      'medium_importance': 'Medium Importance',
      'low_importance': 'Low Importance',
      'all': 'All',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'no_activity': 'No activity',
      'start_speaking': 'Start speaking to capture',
      'recording': 'Recording...',
      'processing': 'Processing...',
      'tap_to_speak': 'Tap to speak',
      'ready': 'Ready to capture',
      'chunks': 'Chunks',
      'important_memories': 'Important Memories',
      'recent_memories': 'Recent memories',
      'view_all': 'View all',
      'all_memories': 'All memories',
      'browse_and_filter': 'Browse and filter everything',
      'snooze_complete': 'Snooze or complete quickly',
      'major_discussions': 'Major Discussions',
      'how_feeling': 'How are you feeling?',
      'quick_reflections': 'Quick Reflections',
      'past_reflections': 'Past Reflections',
      'todays_journey': "Today's Journey",
      'mood_saved': 'Mood saved',
      'add_goal': 'Add Goal',
      'edit_goal': 'Edit Goal',
      'delete_goal': 'Delete Goal',
      'update_progress': 'Update Progress',
      'total': 'Total',
      'in_progress': 'In Progress',
      'no_goals': 'No goals yet',
      'extracted_goals': 'Goals will be auto-extracted',
      'share': 'Share',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'done': 'Done',
    },
    'hi': {
      'home': 'होम',
      'memories': 'यादें',
      'reminders': 'रिमाइंडर',
      'sessions': 'सत्र',
      'settings': 'सेटिंग्स',
      'search': 'खोजें',
      'daily_summary': 'दैनिक सारांश',
      'timeline': 'टाइमलाइन',
      'reflection': 'विचार',
      'goals': 'लक्ष्य',
      'ask_omi': 'ओमी से पूछें',
      'what_did_we_discuss': 'हमने क्या चर्चा की...',
      'tomorrow_reminders': 'कल के रिमाइंडर',
      'pending_tasks': 'बाकी काम',
      'completed': 'पूरा हुआ',
      'pending': 'बाकी',
      'high_importance': 'उच्च महत्व',
      'medium_importance': 'मध्यम महत्व',
      'low_importance': 'कम महत्व',
      'all': 'सभी',
      'today': 'आज',
      'yesterday': 'कल',
      'no_activity': 'कोई गतिविधि नहीं',
      'start_speaking': 'बोलना शुरू करें',
      'recording': 'रिकॉर्डिंग...',
      'processing': 'प्रोसेसिंग...',
      'tap_to_speak': 'बोलने के लिए टैप करें',
      'ready': 'यादें कैप्चर करने के लिए तैयार',
      'chunks': 'टुकड़े',
      'important_memories': 'महत्वपूर्ण यादें',
      'recent_memories': 'हाल की यादें',
      'view_all': 'सभी देखें',
      'all_memories': 'सभी यादें',
      'browse_and_filter': 'सब कुछ ब्राउज़ और फ़िल्टर करें',
      'snooze_complete': 'स्नूज़ या पूरा करें',
      'major_discussions': 'मुख्य चर्चाएं',
      'how_feeling': 'आप कैसा महसूस कर रहे हैं?',
      'quick_reflections': 'त्वरित विचार',
      'past_reflections': 'पिछले विचार',
      'todays_journey': 'आज की यात्रा',
      'mood_saved': 'मूड सेव किया',
      'add_goal': 'लक्ष्य जोड़ें',
      'edit_goal': 'लक्ष्य संपादित करें',
      'delete_goal': 'लक्ष्य हटाएं',
      'update_progress': 'प्रगति अपडेट करें',
      'total': 'कुल',
      'in_progress': 'जारी है',
      'no_goals': 'अभी कोई लक्ष्य नहीं',
      'extracted_goals': 'लक्ष्य स्वचालित रूप से निकाले जाएंगे',
      'share': 'शेयर करें',
      'cancel': 'रद्द करें',
      'save': 'सेव करें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'done': 'हो गया',
    },
    'gu': {
      'home': 'હોમ',
      'memories': 'યાદો',
      'reminders': 'રિમાઇન્ડર',
      'sessions': 'સેશનો',
      'settings': 'સેટિંગ્સ',
      'search': 'શોધો',
      'daily_summary': 'દૈનિક સારાંશ',
      'timeline': 'ટાઇમલાઇન',
      'reflection': 'પ્રતિબિંબ',
      'goals': 'લક્ષ્યો',
      'ask_omi': 'ઓમીને પૂછો',
      'what_did_we_discuss': 'અમે શું ચર્ચા કરી...',
      'tomorrow_reminders': 'આવતીકાલના રિમાઇન્ડર',
      'pending_tasks': 'પેન્ડિંગ કાર્યો',
      'completed': 'પૂર્ણ',
      'pending': 'પેન્ડિંગ',
      'high_importance': 'ઉચ્ચ મહત્વ',
      'medium_importance': 'મધ્યમ મહત્વ',
      'low_importance': 'નીચું મહત્વ',
      'all': 'બધા',
      'today': 'આજે',
      'yesterday': 'ગઈકાલે',
      'no_activity': 'કોઈ પ્રવૃત્તિ નથી',
      'start_speaking': 'બોલવાનું શરૂ કરો',
      'recording': 'રેકોર્ડિંગ...',
      'processing': 'પ્રોસેસિંગ...',
      'tap_to_speak': 'બોલવા માટે ટૅપ કરો',
      'ready': 'યાદો કેપ્ચર કરવા તૈયાર',
      'chunks': 'ટુકડાઓ',
      'important_memories': 'મહત્વપૂર્ણ યાદો',
      'recent_memories': 'તાજી યાદો',
      'view_all': 'બધા જુઓ',
      'all_memories': 'બધી યાદો',
      'browse_and_filter': 'બધું બ્રાઉઝ અને ફિલ્ટર કરો',
      'snooze_complete': 'સ્નૂઝ અથવા પૂર્ણ કરો',
      'major_discussions': 'મુખ્ય ચર્ચાઓ',
      'how_feeling': 'તમે કેવી રીતે અનુભવો છો?',
      'quick_reflections': 'ઝડપી પ્રતિબિંબ',
      'past_reflections': 'ભૂતકાળના પ્રતિબિંબ',
      'todays_journey': 'આજની યાત્રા',
      'mood_saved': 'મૂડ સેવ થયો',
      'add_goal': 'લક્ષ્ય ઉમેરો',
      'edit_goal': 'લક્ષ્ય સંપાદિત કરો',
      'delete_goal': 'લક્ષ્ય દૂર કરો',
      'update_progress': 'પ્રગતિ અપડેટ કરો',
      'total': 'કુલ',
      'in_progress': 'ચાલુ છે',
      'no_goals': 'હજી કોઈ લક્ષ્ય નથી',
      'extracted_goals': 'લક્ષ્યો આપમેળે કાઢવામાં આવશે',
      'share': 'શેર કરો',
      'cancel': 'રદ કરો',
      'save': 'સેવ કરો',
      'delete': 'દૂર કરો',
      'edit': 'સંપાદિત કરો',
      'done': 'થયું',
    },
  };

  void setLanguage(String languageCode) {
    if (_translations.containsKey(languageCode)) {
      _currentLanguage = languageCode;
      debugPrint('MultilingualUIService: Language set to $languageCode');
    } else {
      debugPrint('MultilingualUIService: Unknown language code $languageCode, defaulting to English');
      _currentLanguage = 'en';
    }
  }

  String get currentLanguage => _currentLanguage;

  String translate(String key) {
    final translations = _translations[_currentLanguage] ?? _translations['en']!;
    return translations[key] ?? _translations['en']![key] ?? key;
  }

  String t(String key) => translate(key);

  List<String> get supportedLanguages => _translations.keys.toList();

  String getLanguageDisplayName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'gu':
        return 'ગુજરાતી';
      default:
        return code;
    }
  }
}
