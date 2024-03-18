#!/bin/sh

# cd this file path
cd $(dirname $0)
echo pwd: `pwd`

Podspec_Path="../Armin.podspec"


# get version
SDK_Version=`grep "spec.version\s*=\s*\"*\"" ${Podspec_Path} | sed -r 's/.*"(.+)".*/\1/'`

echo version: ${SDK_Version}

Tag=${SDK_Version}

# push tag
git tag ${Tag}
git push origin ${Tag}

# publish
pod trunk push ${Podspec_Path} --allow-warnings --verbose
