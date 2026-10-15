# Adivery (Iranian builds). Its optional mediation networks are not bundled,
# so R8 must not fail on their missing classes. Same as Tiaro's setup.
-keep class com.adivery.** { *; }
-dontwarn com.adivery.**
-dontwarn com.chartboost.**
-dontwarn com.huawei.hms.**
-dontwarn com.ironsource.**
-dontwarn com.mbridge.**
-dontwarn com.startapp.**
-dontwarn com.unity3d.**
