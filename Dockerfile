FROM ccr.ccs.tencentyun.com/zhangsync/openjdk:11

ADD kafka /opt/kafka
ADD run.sh /

EXPOSE 9092
EXPOSE 9093

ENV HOME /opt/kafka
ENV PATH=${PATH}:${KAFKA_HOME}/bin

ENV CLUSTER_ID 9dJzdGvfTPaCY4e8klXaDQ

CMD ["/run.sh"]
