FROM java:8-jdk-alpine

RUN apk add --no-cache bash curl git && \
    curl --fail --show-error --output /usr/local/bin/lein \
         https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein && \
    chmod 0755 /usr/local/bin/lein && \
    adduser -D build

USER build
WORKDIR /home/build

RUN lein

ADD target/lambdacd-pipeline-*-standalone.jar /pipeline.jar

CMD ["java", "-jar", "/pipeline.jar" ]
