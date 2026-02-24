# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep Firebase classes from being obfuscated
-keep class com.google.firebase.** { *; }
-keep class com.google.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.gms.**

# Keep Firebase Messaging classes
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# Keep Firebase Core classes
-keep class com.google.firebase.core.** { *; }

# Keep Firebase Auth classes
-keep class com.google.firebase.auth.** { *; }

# Keep Firebase Firestore classes
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firestore.** { *; }

# Firestore internal serialization (uses Gson)
-keepclassmembers class com.google.firebase.firestore.** {
    *;
}

# Preserve Firestore model classes and their generic types
-keep class com.google.firebase.firestore.model.** { *; }
-keep class com.google.firebase.firestore.util.** { *; }

# Keep Firestore converter classes
-keep class * implements com.google.firebase.firestore.FirestoreDataConverter { *; }

# Keep Firebase Storage classes
-keep class com.google.firebase.storage.** { *; }

# Keep Google Play Services classes
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Keep local notifications classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep SQLite classes (sqflite plugin)
-keep class io.flutter.plugins.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# Keep Kotlin metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Preserve generic signatures for Gson (used by Firestore)
# This is critical for TypeToken to work correctly with ProGuard/R8
-keepattributes Signature
-keepattributes *GenericSignature*
-keepattributes Exceptions
-keepattributes InnerClasses

# Gson specific classes
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Gson TypeToken - CRITICAL for Firestore serialization
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Preserve generic type information for collections
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep generic signatures of classes used with Gson
-keepattributes Signature
-keep class * extends java.lang.reflect.Type
-keep class * extends java.lang.reflect.GenericArrayType
-keep class * extends java.lang.reflect.ParameterizedType
-keep class * extends java.lang.reflect.TypeVariable
-keep class * extends java.lang.reflect.WildcardType

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

