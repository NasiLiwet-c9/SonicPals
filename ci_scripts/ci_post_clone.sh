#!/bin/sh

#  ci_post_clone.sh
#  SonicPals
#
#  Created by Shan Newcastle on 08/09/26.

set -e

defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

echo "Package plugin validation skipped for this CI run"
