# 🗺️ Google Maps Setup Fix - Resolve "For Development Only" Error

## The Problem
If you're seeing "For development only" on your Google Maps, it means the API key isn't properly configured with the right permissions and restrictions.

## ✅ Step-by-Step Fix

### 1. **Google Cloud Console Setup**

1. **Go to [Google Cloud Console](https://console.cloud.google.com/)**
2. **Select or Create Project**
3. **Enable Required APIs** (Go to APIs & Services > Library):
   - ✅ Maps JavaScript API
   - ✅ Maps SDK for Android  
   - ✅ Maps SDK for iOS
   - ✅ Places API
   - ✅ Geocoding API
   - ✅ Geolocation API

### 2. **Create/Configure API Key**

1. **Go to APIs & Services > Credentials**
2. **Click "Create Credentials" > "API Key"**
3. **Copy the API key** (you'll need this)
4. **Click "Restrict Key"** (very important!)

### 3. **Configure API Key Restrictions**

#### **Application Restrictions:**
- **HTTP referrers (web sites)**: Add these:
  - `http://localhost:*/*`
  - `https://localhost:*/*` 
  - `https://your-domain.com/*` (if you have a domain)
  - `file:///*` (for local development)

#### **API Restrictions:**
- **Restrict key** and select:
  - Maps JavaScript API
  - Places API
  - Geocoding API

### 4. **Update Your Code**

**Replace in `web/index.html` (line 35):**
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY&libraries=places"></script>
```

**Update `lib/config/api_config.dart`:**
```dart
static const String googleMapsApiKey = 'YOUR_ACTUAL_API_KEY';
```

### 5. **Enable Billing (Required!)**

⚠️ **Google Maps requires billing to be enabled, even for free tier usage**
1. Go to **Billing** in Google Cloud Console
2. **Link a payment method**
3. **Don't worry**: You get $200 free credits monthly
4. **Set budget alerts** to avoid surprises

### 6. **Test the Fix**

1. **Save all files**
2. **Clear browser cache** (important!)
3. **Refresh your app**
4. **Check the Map tab** - Adventure Mode should now work!

---

## 📱 **Mobile App Configuration** (If building for mobile)

### **Android Setup** (`android/app/src/main/AndroidManifest.xml`):
```xml
<application>
    <!-- Add this inside <application> tag -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_ACTUAL_API_KEY" />
</application>
```

### **iOS Setup** (`ios/Runner/AppDelegate.swift`):
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 🔧 **Troubleshooting**

### **Still seeing "For development only"?**
1. ✅ **Check API key is correct** in all files
2. ✅ **Verify billing is enabled** in Google Cloud
3. ✅ **Clear browser cache** completely
4. ✅ **Wait 5-10 minutes** for changes to propagate
5. ✅ **Check browser console** for specific error messages

### **"This API project is not authorized" error?**
- **Solution**: Add your domain to HTTP referrers restrictions

### **Quota exceeded errors?**
- **Solution**: You're likely on free tier - enable billing for full access

### **Maps loading very slowly?**
- **Solution**: Remove unnecessary API restrictions, ensure good internet

---

## 💰 **Cost Information**

**Google Maps Pricing (as of 2024):**
- **Dynamic Maps**: Free for first 28,000 loads/month
- **Static Maps**: Free for first 100,000 loads/month  
- **Places API**: Free for first 17,000 requests/month

**For a typical game app**: Monthly cost will be **$0-$5** unless you have thousands of active users.

---

## ✅ **Quick Test Script**

Add this to test if your API key works:

```html
<!DOCTYPE html>
<html>
<head>
    <title>API Key Test</title>
</head>
<body>
    <div id="map" style="height: 400px; width: 100%;"></div>
    
    <script>
        function initMap() {
            const map = new google.maps.Map(document.getElementById("map"), {
                zoom: 10,
                center: { lat: 51.5074, lng: -0.1278 }, // London
            });
            console.log("✅ Google Maps API working!");
        }
        
        function handleError() {
            console.error("❌ Google Maps API failed to load");
        }
    </script>
    
    <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY&callback=initMap&onerror=handleError"></script>
</body>
</html>
```

If this shows a map = **API key works!**  
If this shows errors = **Follow the setup steps above**

---

Once this is fixed, your Adventure Mode will show:
- ✅ **Real Google Maps** with your location  
- ✅ **Quest markers** showing where to go
- ✅ **Trail overlays** with hiking routes
- ✅ **GPS verification** when you reach locations

**The GPS quest completion system is already built - it just needs the map to work!** 