# Set default build arguments
ARG BUILD_VER=latest
ARG skiptest=false
ARG SONAR_SCAN=enabled
ARG MAVEN_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1 -Xmx1500m -Djava.awt.headless=true -Dmaven.test.failure.ignore=true"
ARG MAVEN_PUBLISH_KEY

# Base build stage. Copy project pom, download dependencies, etc
# Occurs when pom.xml is modified or docker image cache is cleared
FROM maven:3.8.4-jdk-11 AS base
WORKDIR /build
COPY maven_settings.xml .
COPY pom.xml .
COPY set-deploy-version.sh .
ARG BUILD_VER
ENV BUILD_VER=$BUILD_VER
ARG MAVEN_PUBLISH_KEY
ENV MAVEN_PUBLISH_KEY=$MAVEN_PUBLISH_KEY
RUN chmod 755 ./set-deploy-version.sh \
 && bash ./set-deploy-version.sh \
 && mvn -B -e -s maven_settings.xml dependency:resolve-plugins dependency:resolve

# Build and verify project using cached dependencies
FROM base AS build
WORKDIR /build
COPY . .
ARG BUILD_VER
ENV BUILD_VERSION=$BUILD_VER
ARG skiptest
ENV SKIP_TESTS=$skiptest
ARG MAVEN_OPTS
ENV MAVEN_OPTS="$MAVEN_OPTS -DskipTests=$SKIP_TESTS -Dmaven.test.failure.ignore=true"
RUN mkdir -p /build/target/surefire-reports /build/target/jacoco-aggregate \
 && echo "BUILD_VERSION=$BUILD_VERSION SKIP_TESTS=$SKIP_TESTS MAVEN_OPTS=$MAVEN_OPTS" \
 && bash ./set-deploy-version.sh \
 && mvn -B -e -s maven_settings.xml verify

# Analyze source code using Java 17 and injected sonar scanner script
FROM maven:3.8.4-openjdk-17 AS scan
WORKDIR /build
COPY --from=build $MAVEN_CONFIG $MAVEN_CONFIG
COPY --from=build /build .
ARG BUILD_VER
ENV BUILD_VERSION=$BUILD_VER
ARG SONAR_SCAN
ENV SONAR_SCAN=$SONAR_SCAN
ARG MAVEN_OPTS
ENV MAVEN_OPTS=$MAVEN_OPTS
RUN echo "use java 17+ for sonar scan" \
 && echo "BUILD_VERSION=$BUILD_VERSION SONAR_SCAN=$SONAR_SCAN MAVEN_OPTS=$MAVEN_OPTS" \
 && bash ./set-deploy-version.sh \
 && chmod 755 ./sonarscanner/sonarnet.sh \
 && ./sonarscanner/sonarnet.sh mvn validate

# Final deploy stage
FROM maven:3.8.4-jdk-11 AS deploy
WORKDIR /build
COPY --from=scan /build .
COPY --from=scan /build/target/surefire-reports /buildoutput/testoutput
COPY --from=scan /build/target/jacoco-aggregate /buildoutput/jacoco
COPY --from=scan /build/target/*.exec /buildoutput/jacoco/
ARG MAVEN_OPTS
ENV MAVEN_OPTS=$MAVEN_OPTS
ARG PUBLISH
ENV PUBLISH=$PUBLISH
ARG MAVEN_PUBLISH_KEY
ENV MAVEN_PUBLISH_KEY=$MAVEN_PUBLISH_KEY
RUN echo "MAVEN_OPTS=$MAVEN_OPTS PUBLISH=$PUBLISH" \
 && chmod +x ./deploy.sh \
 && ./deploy.sh
