#!/bin/bash
set -e

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
echo "=== iOS SDK Path: $SDK ==="

OBJS=()

compile_file() {
    local src="$1"
    if [ ! -f "$src" ]; then
        echo "Skip missing: $src"
        return
    fi
    local obj="${src//\//_}.o"
    echo "Compiling $src..."
    clang -arch arm64 -isysroot "$SDK" -miphoneos-version-min=15.0 -fobjc-arc -Wno-everything -I. -I./kexploit -I./compat -I./XPF/src -I./XPF/external/ChOma/include -c "$src" -o "$obj"
    OBJS+=("$obj")
}

# Compile explicit source list
SOURCES=(
    "main.m"
    "AppDelegate.m"
    "ZEXInjectorVC.m"
    "ZEXFileService.m"
    "MCMBridge.m"
    "MCMFilzaIntegration.m"
    "sandbox_escape.m"
    "apfs_own.m"
    "kexploit/kexploit_opa334.m"
    "kexploit/krw.m"
    "kexploit/kutils.m"
    "kexploit/offsets.m"
    "kexploit/vnode.m"
    "kpf/patchfinder.m"
    "utils/file.c"
    "utils/hexdump.c"
    "utils/process.c"
)

for f in "${SOURCES[@]}"; do
    compile_file "$f"
done

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
