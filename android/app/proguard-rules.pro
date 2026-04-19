# Keep generic signatures for Gson/TypeToken
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep flutter_local_notifications plugin classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
