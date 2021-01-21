#!/bin/bash

# Sets you up to make a hotfix.  Pass in release name, no prefixed `v`.

export RELEASE_OR_HOTFIX=$1
VERSION=$2

if [[ $RELEASE_OR_HOTFIX == "release" || ($RELEASE_OR_HOTFIX == "hotfix") ]]
then
    echo "You have selected $RELEASE_OR_HOTFIX"
else
    echo "usage: You must specify one of release or hotfix. eg $0 release 3.0.0"
    exit -1
fi

if [ -z $VERSION ]
then
    echo "usage: Pass in hotfix name, no prefixed 'v'."
    exit -1
fi

set -x
set -e

# confirm that git flow is present:
git flow version

# confirm the `public` remote exists:
git ls-remote public

# confirm that working directory has no untracked stuff:
git diff-index --quiet HEAD --

# make sure remote is refresh:
git fetch origin

git checkout master

# destroy master state!
git reset --hard origin/master

git checkout develop

# destroy develop state!
git reset --hard origin/develop

echo "Making $RELEASE_OR_HOTFIX branch for: $VERSION"

if [ $RELEASE_OR_HOTFIX == "hotfix" ]
then
    echo "Assuming hotfix branch already exists."
    git checkout hotfix/$VERSION
    echo "Verifying SDK."

    # Sadly xcodebuld/swiftpm aren't co-operating, so no verification in the script for now.
    # xcodebuild -project ClipSample/ClipSample.xcodeproj
else
    git checkout master
    echo "Verifying SDK."
    # Sadly xcodebuld/swiftpm aren't co-operating, so no verification in the script for now.
    # xcodebuild -project ClipSample/ClipSample.xcodeproj

    git flow $RELEASE_OR_HOTFIX start $VERSION
fi

git commit --allow-empty -a -m "Releasing $VERSION."

git flow $RELEASE_OR_HOTFIX finish $VERSION

git push origin master
git push origin develop

git push origin $VERSION

echo "Deploying to the public repo..."
git fetch public
git branch -D public-master
git checkout -b public-master --track public/master
# replace index with that of the freshly minted master
git restore -s master -W -S .
git commit -m "Releasing $VERSION."
git push public public-master:master

echo "Done! 🎉 (create the tag yourself in public repo in github ui)"
