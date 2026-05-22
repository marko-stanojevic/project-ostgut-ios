#!/bin/zsh
set -e

# Inject Xcode Cloud build number so CURRENT_PROJECT_VERSION increments
# monotonically across all builds. CI_BUILD_NUMBER is set by Xcode Cloud;
# the script is a no-op in local builds.
if [[ -n "$CI_BUILD_NUMBER" ]]; then
    xcrun agvtool new-version -all "$CI_BUILD_NUMBER"
fi
