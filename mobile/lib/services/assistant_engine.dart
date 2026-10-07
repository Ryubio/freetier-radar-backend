import '../l10n/app_strings.dart';

class AssistantEngine {
  static final Map<String, List<String>> _keywords = {
    'web': ['web', 'site', 'frontend', 'react', 'vue', 'html', 'arayüz', 'веб', 'сайт', 'фронтенд'],
    'mobile': ['mobile', 'app', 'ios', 'android', 'flutter', 'mobil', 'uygulama', 'telefon', 'мобильный', 'приложение'],
    'db': ['database', 'data', 'sql', 'nosql', 'store', 'veritabanı', 'veri', 'kayıt', 'база данных', 'данные'],
    'auth': ['auth', 'login', 'user', 'register', 'giriş', 'kayıt', 'kullanıcı', 'üye', 'авторизация', 'логин', 'пользователь'],
    'storage': ['image', 'photo', 'file', 'storage', 'resim', 'fotoğraf', 'dosya', 'depolama', 'изображение', 'фото', 'файл', 'хранилище'],
    'ai': ['ai', 'machine learning', 'llm', 'chatgpt', 'yapay zeka', 'ии', 'нейросеть'],
  };

  static String analyzeAndRecommend(String input, String locale) {
    input = input.toLowerCase();
    
    bool needsWeb = _keywords['web']!.any((k) => input.contains(k));
    bool needsMobile = _keywords['mobile']!.any((k) => input.contains(k));
    bool needsDb = _keywords['db']!.any((k) => input.contains(k));
    bool needsAuth = _keywords['auth']!.any((k) => input.contains(k));
    bool needsStorage = _keywords['storage']!.any((k) => input.contains(k));
    bool needsAi = _keywords['ai']!.any((k) => input.contains(k));

    if (!needsWeb && !needsMobile && !needsDb && !needsAuth && !needsStorage && !needsAi) {
      return AppStrings.get('assistant_empty', locale);
    }

    String response = AppStrings.get('assistant_found', locale);

    if (needsWeb) {
      response += AppStrings.get('detect_web', locale) + "Vercel, Netlify, Cloudflare Pages\n";
    }
    if (needsMobile) {
      response += AppStrings.get('detect_mobile', locale) + "Firebase (Crashlytics, FCM)\n";
    }
    if (needsDb) {
      response += AppStrings.get('detect_db', locale) + "Supabase, Neon (Postgres), MongoDB Atlas\n";
    }
    if (needsAuth) {
      response += AppStrings.get('detect_auth', locale) + "Clerk, Kinde, Supabase Auth\n";
    }
    if (needsStorage) {
      response += AppStrings.get('detect_storage', locale) + "Cloudinary, Uploadthing, AWS S3 Free Tier\n";
    }
    if (needsAi) {
      response += AppStrings.get('detect_ai', locale) + "Hugging Face, Gemini API, Together AI\n";
    }

    return response;
  }
}
