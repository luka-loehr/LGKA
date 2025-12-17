#!/bin/bash

# Script to check keystore details and help configure signing

echo "LGKA+ Keystore Configuration Helper"
echo "===================================="
echo

# Check if keystore exists
if [ -f "keystore/keystore_lgka.p12" ]; then
    echo "[OK] Keystore found: keystore/keystore_lgka.p12"
    echo
    
    echo "Keystore Details:"
    echo "-----------------"
    keytool -list -v -keystore keystore/keystore_lgka.p12 -storetype PKCS12
    echo
    
    echo "To configure signing:"
    echo "1. Edit android/key.properties"
    echo "2. Replace the placeholder values with:"
    echo "   - storePassword: Your P12 password"
    echo "   - keyPassword: Your private key password"
    echo "   - keyAlias: The alias shown above"
    echo
    echo "3. Then run: flutter build appbundle --release"
    
else
    echo "[ERROR] Keystore not found at keystore/keystore_lgka.p12"
    echo "Please ensure your keystore file is in the keystore/ directory"
fi

echo
echo "Current file structure:"
echo "-----------------------"
echo "keystore/"
ls -la keystore/ 2>/dev/null || echo "  (directory not found)"
echo
echo "android/key.properties:"
if [ -f "android/key.properties" ]; then
    cat android/key.properties
else
    echo "  (file not found)"
fi
