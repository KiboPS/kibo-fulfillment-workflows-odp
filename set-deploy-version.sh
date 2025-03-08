#!/bin/bash

OVERRIDE_VERSION=""
echo "BUILD_VER $BUILD_VER"

# if BUILD_VER is 1.2510.0-pr-123.10, then change pom version to pr-123-SNAPSHOT
regex="^[0-9]+\.[0-9]{4}\.[0-9]+-(.*)\.[0-9]+$"
if [[ $BUILD_VER =~ $regex ]]; then
  echo "branch is ${BASH_REMATCH[1]}"
  branch=${BASH_REMATCH[1]}
  if [[ "x$branch" != "x" ]] && [[ "$branch" != "develop" ]]; then
    echo "BUILD_VER $BUILD_VER is a development version"
    OVERRIDE_VERSION="${branch}-SNAPSHOT"
  fi
fi

if [ "x$OVERRIDE_VERSION" != "x" ]; then
  echo "overriding version to $OVERRIDE_VERSION"
  mvn versions:set -DnewVersion=$OVERRIDE_VERSION
fi
