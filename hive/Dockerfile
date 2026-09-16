# =============================================================================
# Hive 3.1.3 with PostgreSQL metastore.
# Multi-stage build: the official apache/hive base image is minimal and does NOT
# reliably ship curl / wget / package managers, so we download the JDBC driver in
# a separate well-known builder stage and copy the jar into the final image.
# =============================================================================

# ---------- Stage 1: fetch the PostgreSQL JDBC driver ----------
FROM docker.1ms.run/eclipse-temurin:8-jdk-jammy AS jdbc
ARG POSTGRES_JDBC_VERSION=42.7.3
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /opt/jdbc; \
    jar="postgresql-${POSTGRES_JDBC_VERSION}.jar"; \
    if curl -fsSL "https://maven.aliyun.com/repository/public/org/postgresql/postgresql/${POSTGRES_JDBC_VERSION}/${jar}" -o "/opt/jdbc/${jar}"; then \
        echo "downloaded from aliyun maven"; \
    else \
        echo "aliyun failed, falling back to maven central"; \
        curl -fsSL "https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_JDBC_VERSION}/${jar}" -o "/opt/jdbc/${jar}"; \
    fi; \
    ls -l /opt/jdbc

# ---------- Stage 2: Hive runtime image ----------
FROM docker.1ms.run/apache/hive:3.1.3

USER root

ENV HIVE_HOME=/opt/hive
ENV HIVE_CONF_DIR=/opt/hive/conf
ENV HIVE_VERSION=3.1.3
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop

# PostgreSQL JDBC driver from the builder stage
COPY --from=jdbc /opt/jdbc/postgresql-*.jar ${HIVE_HOME}/lib/

# Hudi mr bundle: lets HiveServer2 query Hudi tables (INPUTFORMAT
# org.apache.hudi.hadoop.HoodieParquetInputFormat lives here).
# The bundle is fully shaded (parquet/avro/hbase under org.apache.hudi.*),
# so it does NOT conflict with Hive's own parquet 1.10 jars.
COPY hudi-hadoop-mr-bundle-*.jar ${HIVE_HOME}/lib/

# Hadoop client config (core-site/hdfs-site) so Hive can reach HDFS
COPY hadoop-conf/ /opt/hadoop/etc/hadoop/
COPY conf/ /opt/hive/conf/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
