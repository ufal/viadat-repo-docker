FROM ubuntu:xenial as base

RUN apt-get update && apt-get install -y --no-install-recommends \
        httpie \
        lsof \
        htop \
        less \
        time \
        build-essential \
        zlib1g-dev \
        libssl-dev \
        libxml2-dev \
        git-core \
        sudo \
        locales \
        openssh-client \
        curl \
        vim \
        wget \
        byobu \
        git \
        bash-completion \
        software-properties-common \
        postgresql-client \
        openjdk-8-jdk-headless \
        libxml2-utils \
        ant \
        maven \
        unzip && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN locale-gen en_US.UTF-8
# Define commonly used JAVA_HOME variable and Locale
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

WORKDIR /tmp

#DCEVM installation
#Since DCEVM for Xenial seems kind of broken, we download it from zetzy
RUN http --follow GET https://mirrors.kernel.org/ubuntu/pool/universe/o/openjdk-8-jre-dcevm/openjdk-8-jre-dcevm_8u112-2_amd64.deb > openjdk-8-jre-dcevm_8u112-2_amd64.deb && \
    dpkg -i openjdk-8-jre-dcevm_8u112-2_amd64.deb

# Install Tomcat 8
ENV CATALINA_HOME=/usr/local/tomcat
ENV TOMCAT_MAJOR=8 TOMCAT_VERSION=8.0.44
ENV TOMCAT_TGZ_URL=https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz
RUN mkdir -p $CATALINA_HOME
RUN wget "$TOMCAT_TGZ_URL" -O tomcat.tar.gz \
    && tar -xvf tomcat.tar.gz --strip-components=1 -C "$CATALINA_HOME"
ENV PATH=$CATALINA_HOME/bin:$PATH

###
# Tomcat configuration tweaks
###

# Configure remote debugging and extra memory
COPY conf/tomcat/setenv.sh $CATALINA_HOME/bin

COPY conf/tomcat/conf $CATALINA_HOME/conf

#Create DSpace folders
RUN mkdir -p /srv/dspace
ENV DSPACE_HOME=/srv/dspace
ENV PATH=$DSPACE_HOME/bin:$PATH

###
# Bash configuration
###

#Configure colors and autocompletion
COPY conf/bash/bashrc /root/.bashrc
COPY conf/bash/bashrc /home/developer/.bashrc

#Configure some useful aliases
COPY conf/bash/bash_aliases /root/.bash_aliases
COPY conf/bash/bash_aliases /home/developer/.bash_aliases

ENV DSPACE_HOME=/srv/dspace
ENV PATH=$DSPACE_HOME/bin:$PATH
#Install Hotswap agent
#COPY HotswapAgent-0.3.zip /usr/lib/hotswapagent/HotswapAgent-0.3.zip
RUN wget https://github.com/HotswapProjects/HotswapAgent/releases/download/RELEASE-0.3/HotswapAgent-0.3.zip -O HotswapAgent.zip
RUN mkdir /usr/lib/hotswapagent
RUN unzip HotswapAgent.zip -d /usr/lib/hotswapagent/
RUN rm HotswapAgent.zip

RUN export HOME=/home/developer
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

#Also, give developer ownership of CATALINA_HOME
RUN chown -R developer:developer $CATALINA_HOME

#Uncomment this lines to set a custom UID. E.g.: 1009
#RUN export uid=1009 && usermod -u $uid developer
#RUN  chown -R developer:developer /home/developer

#COPY dspace-src /srv/dspace-src
#RUN ln -nsf /srv/dspace-src /srv/dspace-src/utilities/project_helpers/sources
COPY dspace_after_install_init /dspace_after_install_init
WORKDIR /dspace_after_install_init
RUN chmod +x ./init.sh && chown -R developer /srv && chown -R developer /opt
# deploy_guru can't work during build, no src mounted postgres available
#RUN ./init.sh


USER developer

EXPOSE 1043:1043
EXPOSE 8080:8080
EXPOSE 8000:8000


FROM base as copied
RUN git clone -b local_changes https://github.com/kosarko/DSpace /srv/dspace-src
# COPY configs including changes to security of webapps
COPY conf/repo/local.properties /srv/dspace-src
COPY conf/repo/variable.makefile /srv/dspace-src/utilities/project_helpers/config
COPY conf/repo/webapp/rest/web.xml /srv/dspace-src/dspace-rest/src/main/webapp/WEB-INF/web.xml
COPY conf/repo/webapp/solr/web.xml /srv/dspace-src/dspace-solr/src/main/webapp/WEB-INF/web.xml
WORKDIR /srv/dspace-src/utilities/project_helpers/scripts
RUN make install_libs deploy_guru && rm -rf /srv/dspace-src ~/.m2

FROM base as final
COPY --from=copied /srv/dspace /srv/dspace
COPY --from=copied /opt/lindat-common /opt/lindat-common
USER root
run mkdir /srv/dspace/assetstore && mkdir /srv/dspace/log && chown -R developer:developer /srv
USER developer
WORKDIR /srv/dspace

CMD ["/usr/local/tomcat/bin/catalina.sh", "jpda", "run"]
VOLUME ["/srv/dspace/assetstore",  "/srv/dspace/log",  "/srv/dspace/solr"]
