FROM ubuntu:16.04
MAINTAINER Prographer J<prographer.j@gmail.com>

USER root

ARG HADOOP_VERSION=2.7.3

#install dev tools
RUN apt-get update
RUN apt-get install -y curl tar sudo openssh-server openssh-client rsync  net-tools

#ssh setting
ADD config/ssh-config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN /usr/bin/ssh-keygen -A

RUN echo "/usr/sbin/sshd" >> ~/.bashrc

# java
RUN mkdir -p /usr/java/default && \
    curl -Ls 'http://download.oracle.com/otn-pub/java/jdk/8u111-b14/jdk-8u111-linux-x64.tar.gz' -H 'Cookie: oraclelicense=accept-securebackup-cookie' | \
    tar --strip-components=1 -xz -C /usr/java/default/

ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin
RUN ln -s $JAVA_HOME/bin/java /usr/bin/java

# hadoop
RUN curl -s http://apache.tt.co.kr/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./hadoop-$HADOOP_VERSION hadoop
RUN cd /usr/local/hadoop && mkdir -p logs

ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

ENV PATH $PATH:$HADOOP_PREFIX/bin
ENV PATH $PATH:$HADOOP_PREFIX/sbin

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/default\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_PREFIX=/usr/local/hadoop\n:' $HADOOP_CONF_DIR/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_CONF_DIR/hadoop-env.sh

#copy config
ADD config/core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml
ADD config/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
ADD config/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD config/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
ADD config/slaves $HADOOP_PREFIX/etc/hadoop/slaves

RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN service ssh start

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
EXPOSE 10020 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 22
