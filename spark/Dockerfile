# Spark 3.4.3 image bundled with Hudi 0.14.1 (Hive-enabled distribution)
# plus the PostgreSQL JDBC and Kafka connector jars.
FROM docker.1ms.run/eclipse-temurin:8-jdk-jammy

ARG SPARK_VERSION=3.4.3
ARG HADOOP_CLIENT_VERSION=3.3.6
ARG HUDI_VERSION=0.14.1
ARG SCALA_BIN_VERSION=2.12
ARG POSTGRES_JDBC_VERSION=42.7.3
ARG SPARK_KAFKA_VERSION=3.4.1

ENV SPARK_VERSION=${SPARK_VERSION}
ENV SPARK_HOME=/opt/spark
ENV HADOOP_VERSION=${HADOOP_CLIENT_VERSION}
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV JAVA_HOME=/opt/java/openjdk
ENV PYSPARK_PYTHON=python3
ENV PATH=$PATH:${SPARK_HOME}/bin:${SPARK_HOME}/sbin

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget procps netcat-openbsd vim less python3 python3-pip ca-certificates bash \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Spark: try domestic mirrors first. NOTE: Spark 3.4.3 is NO LONGER on
# aliyun / tsinghua apache mirrors (404); huawei still carries it. Archive is
# the last fallback (slow in CN).
# -----------------------------------------------------------------------------
RUN set -eux; \
    file="spark-${SPARK_VERSION}-bin-hadoop3.tgz"; \
    dir="spark/spark-${SPARK_VERSION}"; \
    ok=0; \
    for base in \
        "https://mirrors.huaweicloud.com/apache" \
        "https://mirrors.aliyun.com/apache" \
        "https://mirrors.tuna.tsinghua.edu.cn/apache" \
        "https://archive.apache.org/dist" \
    ; do \
        echo ">>> trying ${base}/${dir}/${file}"; \
        if wget -q --tries=3 --timeout=30 --progress=dot:giga "${base}/${dir}/${file}" -O /tmp/spark.tgz; then \
            ok=1; break; \
        fi; \
    done; \
    [ "${ok}" = "1" ] || { echo "ERROR: all Spark mirrors failed"; exit 1; }; \
    tar -xzf /tmp/spark.tgz -C /opt; \
    mv "/opt/spark-${SPARK_VERSION}-bin-hadoop3" "${SPARK_HOME}"; \
    rm -f /tmp/spark.tgz

# Hadoop client config only (reuse HDFS/YARN from the hadoop image)
RUN mkdir -p ${HADOOP_HOME}/etc/hadoop

# -----------------------------------------------------------------------------
# Extra jars: aliyun Maven first, Maven Central fallback.
# -----------------------------------------------------------------------------
RUN set -eux; \
    fetch() { \
      path="$1"; shift; \
      for base in "$@"; do \
        echo ">>> ${base}${path}"; \
        if wget -q --tries=3 --timeout=60 "${base}${path}" -P "${SPARK_HOME}/jars"; then return 0; fi; \
      done; \
      return 1; \
    }; \
    M1="https://maven.aliyun.com/repository/public"; \
    M2="https://repo1.maven.org/maven2"; \
    fetch "/org/apache/hudi/hudi-spark3.4-bundle_${SCALA_BIN_VERSION}/${HUDI_VERSION}/hudi-spark3.4-bundle_${SCALA_BIN_VERSION}-${HUDI_VERSION}.jar" "$M1" "$M2"; \
    fetch "/org/postgresql/postgresql/${POSTGRES_JDBC_VERSION}/postgresql-${POSTGRES_JDBC_VERSION}.jar" "$M1" "$M2"; \
    fetch "/org/apache/spark/spark-sql-kafka-0-10_${SCALA_BIN_VERSION}/${SPARK_VERSION}/spark-sql-kafka-0-10_${SCALA_BIN_VERSION}-${SPARK_VERSION}.jar" "$M1" "$M2"; \
    fetch "/org/apache/spark/spark-token-provider-kafka-0-10_${SCALA_BIN_VERSION}/${SPARK_VERSION}/spark-token-provider-kafka-0-10_${SCALA_BIN_VERSION}-${SPARK_VERSION}.jar" "$M1" "$M2"; \
    fetch "/org/apache/kafka/kafka-clients/${SPARK_KAFKA_VERSION}/kafka-clients-${SPARK_KAFKA_VERSION}.jar" "$M1" "$M2"

# Optional: Hadoop AWS + aws-java-sdk for S3A. Uncomment if you need S3.
# RUN set -eux; \
#     fetch() { path="$1"; shift; for base in "$@"; do wget -q "${base}${path}" -P "${SPARK_HOME}/jars" && return 0; done; return 1; }; \
#     M1="https://maven.aliyun.com/repository/public"; M2="https://repo1.maven.org/maven2"; \
#     fetch "/org/apache/hadoop/hadoop-aws/${HADOOP_CLIENT_VERSION}/hadoop-aws-${HADOOP_CLIENT_VERSION}.jar" "$M1" "$M2"; \
#     fetch "/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar" "$M1" "$M2"

COPY hadoop-conf/ ${HADOOP_HOME}/etc/hadoop/
COPY conf/ ${SPARK_HOME}/conf/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR ${SPARK_HOME}
EXPOSE 7077 8080 8081 4040 18080 10000

ENTRYPOINT ["/entrypoint.sh"]
