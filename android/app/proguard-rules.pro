# flutter_local_notifications — receivers + models (R8 enabled by Flutter release default).
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Gson rules — required for loadScheduledNotifications / zonedSchedule persistence.
# See flutter_local_notifications example/android/app/proguard-rules.pro
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }
