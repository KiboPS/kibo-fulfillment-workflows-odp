#!/bin/bash

echo "MAVEN_OPTS=$MAVEN_OPTS PUBLISH=$PUBLISH"

if [ "$PUBLISH" = "true" ]; then
  sed -i -r "s/MAVENPUBLISHKEY/${MAVEN_PUBLISH_KEY}/g" maven_settings.xml
  mvn -B -e -s maven_settings.xml deploy -fn -P nexus-deploy -DskipTests -DskipITs
else
  echo "Skipping deployment as PUBLISH is not set to true."
fi
