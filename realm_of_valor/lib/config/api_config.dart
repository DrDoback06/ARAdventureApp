class ApiConfig {
  // Weather Services
  static const String metOfficeApiKey = 'YOUR_MET_OFFICE_API_KEY'; // Optional - UK only
  static const String openWeatherApiKey = '6607a000b24b386d7433a40ff4cc068c';
  
  // Strava Integration - Get from developers.strava.com
  static const String stravaClientId = '167388';
  static const String stravaClientSecret = '61689135684e7ca1668a49623ab31b493580f0ad';
  static const String stravaAccessToken = '1306858f83dbd28f251d09885d50848a86563f39';
  static const String stravaRefreshToken = 'r1bfc173f9abb911f201901e92b099fa6bf3b31ea';
  static const String stravaRedirectUri = 'com.realmofvalor.app://auth';
  
  // Google Maps (add if needed)
  static const String googleMapsApiKey = 'AIzaSyBJoOf8e7Lw2fiFoTY3etNTTkBu-JKhOQQ';
  
  // Trail/Hiking APIs - Choose one or multiple
  // Option 1: Hiking Project API (by REI) - FREE with registration
  static const String hikingProjectApiKey = 'YOUR_HIKING_PROJECT_API_KEY'; // Get from ridb.recreation.gov
  
  // Option 2: AllTrails API (Business partners only, but we can try)
  static const String allTrailsApiKey = 'YOUR_ALLTRAILS_API_KEY';
  
  // Option 3: TrailAPI (Alternative trail data)
  static const String trailApiKey = 'YOUR_TRAIL_API_KEY';
  
  // Check if APIs are configured
  static bool get isWeatherConfigured => 
      metOfficeApiKey != 'YOUR_MET_OFFICE_API_KEY' || 
      openWeatherApiKey != 'YOUR_OPENWEATHER_API_KEY';
      
  static bool get isStravaConfigured => 
      stravaClientId != 'YOUR_STRAVA_CLIENT_ID' && 
      stravaClientSecret != 'YOUR_STRAVA_CLIENT_SECRET';
      
  static bool get isTrailDataConfigured =>
      hikingProjectApiKey != 'YOUR_HIKING_PROJECT_API_KEY' ||
      allTrailsApiKey != 'YOUR_ALLTRAILS_API_KEY' ||
      trailApiKey != 'YOUR_TRAIL_API_KEY';
} 