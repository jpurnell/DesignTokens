#!/bin/bash
# Builds the two libraries a consuming app links (DesignTokens, DesignTokensSwiftUI) for every Apple platform the
# package claims to serve, so a call that one platform marks unavailable (posix_spawn on tvOS and watchOS was the first)
# fails here instead of in an adopter's build. Usage: scripts/check-platforms.sh [platform ...]
# Platforms: macOS iOS tvOS visionOS watchOS (default: all). A platform whose SDK is not installed is reported as
# SKIPPED, and the script exits 2 if anything was skipped, so a skip is never read as a pass.
set -u
cd "$(dirname "$0")/.."

destination() {
    case "$1" in
        macOS) echo "generic/platform=macOS" ;;
        iOS) echo "generic/platform=iOS Simulator" ;;
        tvOS) echo "generic/platform=tvOS Simulator" ;;
        visionOS) echo "generic/platform=visionOS Simulator" ;;
        watchOS) echo "generic/platform=watchOS Simulator" ;;
        *) return 1 ;;
    esac
}

sdk_installed() {
    case "$1" in
        macOS) xcodebuild -showsdks 2>/dev/null | grep -q "macosx" ;;
        iOS) xcodebuild -showsdks 2>/dev/null | grep -q "iphonesimulator" ;;
        tvOS) xcodebuild -showsdks 2>/dev/null | grep -q "appletvsimulator" ;;
        visionOS) xcodebuild -showsdks 2>/dev/null | grep -q "xrsimulator" ;;
        watchOS) xcodebuild -showsdks 2>/dev/null | grep -q "watchsimulator" ;;
    esac
}

platforms=("$@")
[ ${#platforms[@]} -eq 0 ] && platforms=(macOS iOS tvOS visionOS watchOS)

failed=0
skipped=0
for platform in "${platforms[@]}"; do
    dest=$(destination "$platform") || { echo "unknown platform: $platform"; exit 64; }
    if ! sdk_installed "$platform"; then
        echo "SKIPPED  $platform (no SDK installed: xcodebuild -downloadPlatform $platform)"
        skipped=1
        continue
    fi
    for scheme in DesignTokens DesignTokensSwiftUI; do
        log=$(mktemp)
        if xcodebuild -scheme "$scheme" -destination "$dest" -skipPackagePluginValidation build >"$log" 2>&1; then
            echo "ok       $platform  $scheme"
        else
            echo "FAILED   $platform  $scheme"
            grep -E "error:" "$log" | sort -u | head -5
            failed=1
        fi
        rm -f "$log"
    done
done

[ $failed -ne 0 ] && exit 1
[ $skipped -ne 0 ] && exit 2
exit 0
