# API Setup Guide for Adventure Mode

## 🗺️ Google Maps Setup (REQUIRED)

### 1. Get Google Maps API Key
- Go to [Google Cloud Console](https://console.cloud.google.com/)
- Create/select project
- Enable these APIs:
  - Maps JavaScript API
  - Places API  
  - Geocoding API
- Create API Key in Credentials

### 2. Update Files
Replace `YOUR_GOOGLE_MAPS_API_KEY` in:

**File: `web/index.html`** (line 33)
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY&libraries=places"></script>
```

**File: `android/app/src/main/AndroidManifest.xml`** (add if missing)
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_ACTUAL_API_KEY"/>
```

**File: `ios/Runner/AppDelegate.swift`** (add if missing)
```swift
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY")
```

## 🌤️ Weather APIs (OPTIONAL)
Edit `lib/config/api_config.dart`:
- **Met Office API**: [Get key here](https://www.metoffice.gov.uk/services/data/datapoint)
- **OpenWeatherMap**: [Get key here](https://openweathermap.org/api)

## 🏃 Strava Integration (OPTIONAL)
Edit `lib/config/api_config.dart`:
- **Strava App**: [Create app here](https://developers.strava.com/)

## Quick Test
After adding Google Maps API key:
1. Save files
2. Refresh browser 
3. Map tab should show Adventure Mode section
4. "Full Map" button should open Google Maps view

**Note**: Without Google Maps API key, Adventure Mode cannot function properly. 