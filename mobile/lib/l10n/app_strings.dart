class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'explore': 'Explore',
      'bookmarks': 'Bookmarks',
      'settings': 'Settings',
      'assistant': 'AI Assistant',
      'search_hint': 'Search 1300+ services...',
      'language': 'Language',
      'appearance': 'Appearance',
      'data_management': 'Data Management',
      'danger_zone': 'Danger Zone',
      'assistant_greeting': 'Hello! I am your local AI. Tell me about the project you want to build (e.g., "I want to build a mobile chat app with a database and image storage"), and I will recommend the best free-tier stack.',
      'assistant_typing': 'Analyzing project needs...',
      'assistant_hint': 'Describe your project...',
      'assistant_empty': 'I could not detect any specific requirements. Could you add more details like "I need a database" or "It is a web app"?',
      'assistant_found': 'Based on your description, here is the perfect free-tier stack for you:\n\n',
      'detect_web': '🌐 **Hosting / Web:** ',
      'detect_mobile': '📱 **Mobile / App:** ',
      'detect_db': '💾 **Database:** ',
      'detect_auth': '🔒 **Auth:** ',
      'detect_storage': '📂 **Storage:** ',
      'detect_ai': '🤖 **AI / ML:** ',
    },
    'tr': {
      'explore': 'Keşfet',
      'bookmarks': 'Kaydedilenler',
      'settings': 'Ayarlar',
      'assistant': 'Yapay Zeka',
      'search_hint': '1300+ servis içinde ara...',
      'language': 'Dil (Language)',
      'appearance': 'Görünüm',
      'data_management': 'Veri Yönetimi',
      'danger_zone': 'Tehlikeli Alan',
      'assistant_greeting': 'Merhaba! Ben yerel yapay zeka asistanınım. Ne tür bir proje geliştirmek istediğini anlat (Örn: "Veritabanı ve resim yükleme olan bir mobil sohbet uygulaması yapacağım"), sana en iyi ücretsiz mimariyi önereyim.',
      'assistant_typing': 'Proje gereksinimleri analiz ediliyor...',
      'assistant_hint': 'Projeni anlat...',
      'assistant_empty': 'Net bir gereksinim tespit edemedim. "Veritabanı lazım" veya "Web sitesi olacak" gibi detaylar ekleyebilir misin?',
      'assistant_found': 'Anlattıklarına göre projen için en iyi ücretsiz servis mimarisi şu şekilde:\n\n',
      'detect_web': '🌐 **Sunucu / Web:** ',
      'detect_mobile': '📱 **Mobil / Uygulama:** ',
      'detect_db': '💾 **Veritabanı:** ',
      'detect_auth': '🔒 **Kimlik Doğrulama:** ',
      'detect_storage': '📂 **Dosya / Resim:** ',
      'detect_ai': '🤖 **Yapay Zeka / ML:** ',
    },
    'ru': {
      'explore': 'Обзор',
      'bookmarks': 'Закладки',
      'settings': 'Настройки',
      'assistant': 'ИИ Ассистент',
      'search_hint': 'Поиск из 1300+ сервисов...',
      'language': 'Язык (Language)',
      'appearance': 'Внешний вид',
      'data_management': 'Управление данными',
      'danger_zone': 'Опасная зона',
      'assistant_greeting': 'Привет! Я ваш локальный ИИ. Расскажите о проекте, который хотите создать (например: "Я делаю мобильный чат с базой данных и хранением фото"), и я подберу лучший бесплатный стек.',
      'assistant_typing': 'Анализ требований проекта...',
      'assistant_hint': 'Опишите ваш проект...',
      'assistant_empty': 'Я не смог определить конкретные требования. Не могли бы вы добавить детали, например, "мне нужна база данных" или "это веб-приложение"?',
      'assistant_found': 'На основе вашего описания, вот идеальный бесплатный стек для вас:\n\n',
      'detect_web': '🌐 **Хостинг / Веб:** ',
      'detect_mobile': '📱 **Мобильный / Приложение:** ',
      'detect_db': '💾 **База данных:** ',
      'detect_auth': '🔒 **Авторизация:** ',
      'detect_storage': '📂 **Хранилище / Файлы:** ',
      'detect_ai': '🤖 **ИИ / ML:** ',
    }
  };

  static String get(String key, String locale) {
    if (!_localizedValues.containsKey(locale)) {
      locale = 'en'; // fallback
    }
    return _localizedValues[locale]?[key] ?? key;
  }
}
