FROM java:8-jdk


RUN apt-get update && \
    apt-get install -y bash \
      curl \
      git \
      fontconfig \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common && \
    curl --fail --show-error --output /usr/local/bin/lein \
         https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein && \
    chmod 0755 /usr/local/bin/lein && \
    useradd --create-home build && \
    mkdir -p /usr/share && \
    cd /usr/share && \
    curl -L https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 | tar xj && \
    ln -s /usr/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs && \
    phantomjs --version && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 | grep -A 1 '9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88' | grep -q 'Docker Release' && \
    add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/debian \
       $(lsb_release -cs) \
       stable" && \
    apt-get update && \
    apt-get install -y docker-ce && \
    rm -rf /var/lib/apt/lists/*

USER build
WORKDIR /home/build

RUN lein

COPY target/lambdacd-pipeline-*-standalone.jar /pipeline.jar

CMD ["java", "-jar", "/pipeline.jar" ]
