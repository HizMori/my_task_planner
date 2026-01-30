# OkHttp
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# OkIO
-keep class okio.** { *; }
-dontwarn okio.**

# Для uCrop (если используется)
-keep class com.yalantis.ucrop** { *; }
-keepclassmembers class com.yalantis.ucrop** { *; }