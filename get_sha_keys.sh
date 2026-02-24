#!/bin/bash
# Bash script to get SHA-1 and SHA-256 keys for Firebase
# This script helps you get the SHA keys needed for FCM to work on real devices

echo "================================================"
echo "Firebase SHA Key Generator"
echo "================================================"
echo ""

# Check if Java/keytool is available
if ! command -v keytool &> /dev/null; then
    echo "ERROR: keytool not found!"
    echo "Please install Java JDK and add it to your PATH."
    echo ""
    echo "Alternatively, you can use:"
    echo "  cd android"
    echo "  ./gradlew signingReport"
    exit 1
fi

# Default debug keystore path
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

# Check if debug keystore exists
if [ ! -f "$DEBUG_KEYSTORE" ]; then
    echo "DEBUG keystore not found at default location: $DEBUG_KEYSTORE"
    echo ""
    read -p "Enter path to your keystore file (or press Enter to use Gradle): " CUSTOM_PATH
    if [ -z "$CUSTOM_PATH" ]; then
        echo ""
        echo "Using Gradle to get SHA keys..."
        echo "Run this command:"
        echo "  cd android"
        echo "  ./gradlew signingReport"
        exit 0
    fi
    KEYSTORE_PATH="$CUSTOM_PATH"
else
    KEYSTORE_PATH="$DEBUG_KEYSTORE"
fi

echo "Using keystore: $KEYSTORE_PATH"
echo ""

# Get alias
read -p "Enter keystore alias (default: androiddebugkey for debug): " ALIAS
if [ -z "$ALIAS" ]; then
    ALIAS="androiddebugkey"
fi

# Get password
read -sp "Enter keystore password (default: android for debug): " PASSWORD
echo ""
if [ -z "$PASSWORD" ]; then
    PASSWORD="android"
fi

echo ""
echo "Getting SHA keys..."
echo ""

# Get SHA keys using keytool
KEYTOOL_OUTPUT=$(keytool -list -v -keystore "$KEYSTORE_PATH" -alias "$ALIAS" -storepass "$PASSWORD" 2>&1)

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get SHA keys!"
    echo "$KEYTOOL_OUTPUT"
    exit 1
fi

# Extract SHA-1 and SHA-256
SHA1=$(echo "$KEYTOOL_OUTPUT" | grep "SHA1:" | sed 's/.*SHA1: //' | tr -d '[:space:]')
SHA256=$(echo "$KEYTOOL_OUTPUT" | grep "SHA256:" | sed 's/.*SHA256: //' | tr -d '[:space:]')

if [ -n "$SHA1" ] && [ -n "$SHA256" ]; then
    echo "================================================"
    echo "SHA Keys Found!"
    echo "================================================"
    echo ""
    echo "SHA-1:"
    echo "$SHA1"
    echo ""
    echo "SHA-256:"
    echo "$SHA256"
    echo ""
    echo "================================================"
    echo "Next Steps:"
    echo "================================================"
    echo "1. Go to Firebase Console: https://console.firebase.google.com/"
    echo "2. Select your project: student-task-manager-4bc6a"
    echo "3. Go to Project Settings (gear icon)"
    echo "4. Scroll down to 'Your apps' section"
    echo "5. Find your Android app and click 'Add fingerprint'"
    echo "6. Paste SHA-1 key and click 'Add fingerprint' again"
    echo "7. Paste SHA-256 key"
    echo "8. Click 'Save'"
    echo ""
    echo "IMPORTANT: Add BOTH debug AND release SHA keys!"
    echo ""
else
    echo "ERROR: Could not extract SHA keys from output!"
    echo ""
    echo "Full output:"
    echo "$KEYTOOL_OUTPUT"
    echo ""
    echo "Try using Gradle instead:"
    echo "  cd android"
    echo "  ./gradlew signingReport"
fi

