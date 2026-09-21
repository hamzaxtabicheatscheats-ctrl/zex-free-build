#!/bin/bash
set -e

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
echo "=== iOS SDK Path: $SDK ==="

OBJS=()

compile_file() {
    local src="$1"
    local obj="${src//\//_}.o"
    echo "Compiling $src..."
    clang -arch arm64 -isysroot "$SDK" -miphoneos-version-min=15.0 -fobjc-arc -Wno-everything -I. -I./kexploit -I./compat -c "$src" -o "$obj"
    OBJS+=("$obj")
}

# Compile exact project files
compile_file "main.m"
compile_file "AppDelegate.m"
compile_file "ZEXInjectorVC.m"
compile_file "ZEXFileService.m"
compile_file "MCMBridge.m"
compile_file "MCMFilzaIntegration.m"
compile_file "sandbox_escape.m"
compile_file "apfs_own.m"

if [ -d "kexploit" ]; then
    compile_file "kexploit/kexploit_opa334.m"
    compile_file "kexploit/krw.m"
    compile_file "kexploit/kutils.m"
    compile_file "kexploit/offsets.m"
    compile_file "kexploit/vnode.m"
fi

echo "=== Linking Binary ==="
clang -arch arm64 -isysroot "$SDK" -miphoneos-version-min=15.0 \
  -Wl,-w \
  -framework UIKit -framework Foundation -framework CoreFoundation \
  -framework Security -framework QuartzCore -framework AVFoundation \
  -framework AudioToolbox -framework ImageIO -framework CoreGraphics \
  -lz \
  -o ZEXInjector \
  "${OBJS[@]}"

echo "=== Packaging IPA ==="
mkdir -p Payload/ZEXInjector.app
cp ZEXInjector Payload/ZEXInjector.app/
cp Info.plist Payload/ZEXInjector.app/ 2>/dev/null || true
if [ -d Resources ]; then
    cp -R Resources/. Payload/ZEXInjector.app/ 2>/dev/null || true
fi

if command -v ldid &> /dev/null; then
    if [ -f entitlements.plist ]; then
        ldid -Sentitlements.plist Payload/ZEXInjector.app/ZEXInjector || true
    else
        ldid -S Payload/ZEXInjector.app/ZEXInjector || true
    fi
fi

zip -qry bankai-ZEXInjector.ipa Payload
ls -lh bankai-ZEXInjector.ipa
echo "=== IPA BUILD COMPLETE ==="
