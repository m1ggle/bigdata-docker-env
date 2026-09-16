#!/bin/bash
# ---------------------------------------------------------------------------
# Runs after the Hadoop NameNode is up. Creates the base HDFS directories
# used by Hive, Spark, Hudi and Flink.
# Execute with:  docker exec namenode /init/10-hdfs-init.sh
# ---------------------------------------------------------------------------
set -e

export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export PATH="$PATH:${HADOOP_HOME}/bin"

echo ">>> creating HDFS directories"
hdfs dfs -mkdir -p /tmp
hdfs dfs -mkdir -p /user/root
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -mkdir -p /warehouse/tablespace/managed/hive
hdfs dfs -mkdir -p /spark-logs
hdfs dfs -mkdir -p /hudi
hdfs dfs -mkdir -p /flink/checkpoints
hdfs dfs -mkdir -p /flink/savepoints

hdfs dfs -chmod -R 777 /tmp /user /warehouse /spark-logs /hudi /flink
hdfs dfs -chown -R hive:hive /warehouse 2>/dev/null || true

echo ">>> HDFS directories ready"
hdfs dfs -ls /
