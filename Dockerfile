FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc

#Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc

#Install Oracle Java 8
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

RUN apt-get install -y mysql-server-5.5 

RUN wget -O - http://download.tanaguru.org/Tanaguru/tanaguru-3.1.0.i386.tar.gz | tar zx

RUN apt-get install -y libmysql-java --no-install-recommends
RUN apt-get install -y libspring-instrument-java --no-install-recommends
RUN apt-get install -y xvfb
RUN wget -O - http://download.cdn.mozilla.net/pub/mozilla.org/firefox/releases/31.4.0esr/linux-x86_64/en-US/firefox-31.4.0esr.tar.bz2 | tar xj

RUN mv tanaguru* tanaguru

COPY my.cnf /etc/mysql/

#tomcat
RUN wget -O - http://www.us.apache.org/dist/tomcat/tomcat-7/v7.0.64/bin/apache-tomcat-7.0.64.tar.gz | tar zx
RUN mv *tomcat* tomcat
RUN ln -s /usr/share/java/spring3-instrument-tomcat.jar /tomcat/lib/spring3-instrument-tomcat.jar
RUN ln -s /usr/share/java/mysql-connector-java.jar /tomcat/lib/mysql-connector-java.jar

#setup
COPY tanaguru.ddl /
RUN mysqld_safe & mysqladmin --wait=5 ping && \
    mysql < tanaguru.ddl && \
    cd /tanaguru && \
    echo yes | ./install.sh --mysql-tg-db tanaguru \
                  --mysql-tg-user tanaguru \
                  --mysql-tg-passwd tanaguru \
                  --tanaguru-url "http://localhost:8080/tanaguru" \
                  --tomcat-webapps /tomcat/webapps \
                  --tomcat-user root \
                  --tg-admin-email admin@email.com \
                  --tg-admin-passwd admin \
                  --firefox-esr-path /firefox/firefox \
                  --display_port ":99" && \
    mysqladmin shutdown

#hack to get tanaguru to work
RUN cp /etc/tanaguru/* /tomcat/webapps/tanaguru/WEB-INF/classes/
ENV CATALINA_OPTS="-DconfDir=/WEB-INF/classes"

#Add runit services
COPY sv /etc/service 

