# Hadoop base image (HDFS + YARN roles in one image)
# Java 8 is used because Hive 3.1.3 is officially validated on Java 8.
FROM docker.1ms.run/eclipse-temurin:8-jdk-jammy

ARG HADOOP_VERSION=3.3.6

ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget procps netcat-openbsd vim less ca-certificates bash \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Download Hadoop: try domestic mirrors first (archive.apache.org is very slow /
# stalls in CN), with timeout + retry, then fall back to other mirrors / archive.
# Hadoop 3.3.6 is available on aliyun / tsinghua / huawei.
# -----------------------------------------------------------------------------
RUN set -eux; \
    file="hadoop-${HADOOP_VERSION}.tar.gz"; \
    dir="hadoop/common/hadoop-${HADOOP_VERSION}"; \
    ok=0; \
    for base in \
        "https://mirrors.aliyun.com/apache" \
        "https://mirrors.tuna.tsinghua.edu.cn/apache" \
        "https://mirrors.huaweicloud.com/apache" \
        "https://archive.apache.org/dist" \
    ; do \
        echo ">>> trying ${base}/${dir}/${file}"; \
        if wget -q --tries=3 --timeout=30 --progress=dot:giga "${base}/${dir}/${file}" -O /tmp/hadoop.tar.gz; then \
            ok=1; break; \
        fi; \
    done; \
    [ "${ok}" = "1" ] || { echo "ERROR: all Hadoop mirrors failed"; exit 1; }; \
    tar -xzf /tmp/hadoop.tar.gz -C /opt; \
    mv "/opt/hadoop-${HADOOP_VERSION}" "${HADOOP_HOME}"; \
    rm -f /tmp/hadoop.tar.gz; \
    mkdir -p /opt/hadoop/data/name /opt/hadoop/data/data /opt/hadoop/logs

COPY conf/*.xml ${HADOOP_CONF_DIR}/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR ${HADOOP_HOME}
EXPOSE 8020 9000 9870 9864 8088 8032 8030 8031 8033

ENTRYPOINT ["/entrypoint.sh"]
