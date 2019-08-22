#FROM ubuntu:xenial
FROM dspace_maven_deps:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
	httpie \
	lsof \
	htop \
	less \
	openssh-client \	
        ca-certificates \
        curl \
        vim \
        wget \
        byobu \
        git \
        bash-completion \
        software-properties-common \
        postgresql-client \
        openjdk-8-jdk \
        libxml2-utils \
        ant \
        maven \
        unzip

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

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

#Create DSpace folders
RUN mkdir -p /srv/dspace /srv/dspace-src
ENV DSPACE_HOME=/srv/dspace
ENV PATH=$DSPACE_HOME/bin:$PATH

#RUN mkdir /root/.m2
#VOLUME /root/.m2


###
# Bash configuration
###

#Configure colors and autocompletion
COPY bashrc /root/.bashrc
COPY bashrc /home/developer/.bashrc

#Configure some useful aliases
COPY bash_aliases /root/.bash_aliases
COPY bash_aliases /home/developer/.bash_aliases

ENV DSPACE_HOME=/srv/dspace
ENV PATH=$DSPACE_HOME/bin:$PATH
###
# Tomcat configuration tweaks
###

# Configure remote debugging and extra memory
COPY setenv.sh $CATALINA_HOME/bin

#Install Hotswap agent
#COPY HotswapAgent-0.3.zip /usr/lib/hotswapagent/HotswapAgent-0.3.zip
RUN wget https://github.com/HotswapProjects/HotswapAgent/releases/download/RELEASE-0.3/HotswapAgent-0.3.zip -O HotswapAgent.zip
RUN mkdir /usr/lib/hotswapagent
RUN unzip HotswapAgent.zip -d /usr/lib/hotswapagent/
RUN rm HotswapAgent.zip

RUN apt install -y sudo

RUN export HOME=/home/developer
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

RUN chown -R developer $CATALINA_HOME

#Install PSI Probe
#RUN wget https://github.com/psi-probe/psi-probe/releases/download/2.4.0/probe-2.4.0.zip -O probe.zip
#RUN unzip probe.zip
# RUN mv probe.war $CATALINA_HOME/webapps/probe.war
RUN wget https://github.com/psi-probe/psi-probe/releases/download/3.2.0/probe.war -O $CATALINA_HOME/webapps/probe.war

COPY conf $CATALINA_HOME/conf

#RUN wget https://deb.nodesource.com/setup_6.x -O -| sudo bash - \
#  && apt-get install nodejs -y
#
#RUN npm install -g grunt bower

###
# Installing an IDE
###

#Download the IDE
#ADD https://download.jetbrains.com/idea/ideaIC-2016.1.2.tar.gz /home/developer/idea

#Required for running Idea IDE
#RUN apt-get install libxext-dev libxrender-dev libxtst-dev -y

#To make intellij work. For some reason, it requires the fonts to be installed
#RUN  apt-get install fontconfig fontconfig-config fonts-dejavu-core fonts-dejavu-extra -y


#Uncomment this lines to set a custom UID. E.g.: 1009
#RUN export uid=1009 && usermod -u $uid developer
#RUN  chown -R developer:developer /home/developer

RUN apt-get install -y locales && locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'


#Also, give developer ownership of CATALINA_HOME
RUN chown -R developer:developer $CATALINA_HOME/
USER developer

#Install ruby deps
RUN sudo apt-get install -y bison build-essential zlib1g-dev libssl-dev libxml2-dev git-core
#RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - \
#  && curl -sSL https://raw.githubusercontent.com/wayneeseguin/rvm/stable/binscripts/rvm-installer | bash -s stable --ruby
#
#RUN bash -c "source ~/.profile \
#  && gem install sass -v 3.3.14  \
#  && gem install compass -v 1.0.1"
#
RUN echo "source ~/.profile" >> ~/.bashrc

###
# Cleanup
###
RUN sudo rm -rf /var/lib/apt/lists/*

USER root
RUN chown -R developer /m2 && ln -s /m2 /home/developer/.m2
#COPY dspace-src /srv/dspace-src
#RUN ln -nsf /srv/dspace-src /srv/dspace-src/utilities/project_helpers/sources
COPY dspace_after_install_init /dspace_after_install_init
WORKDIR /dspace_after_install_init
RUN chmod +x ./init.sh && chown -R developer /srv && chown -R developer /opt
# deploy_guru can't work during build, no postgres available
#RUN ./init.sh


USER developer



WORKDIR /srv/dspace-src

EXPOSE 1043:1043
EXPOSE 8080:8080
EXPOSE 8000:8000
