#!/usr/bin/env bash
set -e

ROLE="${HADOOP_ROLE:-namenode}"

export JAVA_HOME="${JAVA_HOME:-/opt/java/openjdk}"
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
export PATH="$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin"

wait_for() {
  local host="$1" port="$2"
  echo ">>> waiting for ${host}:${port} ..."
  until nc -z "${host}" "${port}"; do sleep 3; done
  echo ">>> ${host}:${port} is up"
}

case "${ROLE}" in
  namenode)
    if [ ! -f "${HADOOP_HOME}/data/name/current/VERSION" ]; then
      echo ">>> Formatting NameNode (first run)"
      hdfs namenode -format -force -nonInteractive
    fi
    exec hdfs namenode
    ;;
  # One-shot init container: waits for the NameNode RPC to be serving, then
  # creates the base HDFS directories used by Hive / Spark / Hudi / Flink.
  # Its completion is used as a dependency gate (service_completed_successfully).
  init)
    wait_for namenode 9000
    echo ">>> waiting for NameNode RPC to be ready ..."
    until hdfs dfs -ls / >/dev/null 2>&1; do sleep 3; done
    # RPC is up but the NameNode may still be in safe mode after a restart
    # (mkdir on existing dirs is a no-op, but chmod REQUIRES safe mode OFF).
    echo ">>> waiting for NameNode to leave safe mode ..."
    until hdfs dfsadmin -safemode get 2>/dev/null | grep -q "OFF"; do sleep 3; done
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
    echo ">>> HDFS init done"
    exit 0
    ;;
  datanode)
    wait_for namenode 9000
    exec hdfs datanode
    ;;
  resourcemanager)
    wait_for namenode 9000
    exec yarn resourcemanager
    ;;
  nodemanager)
    wait_for resourcemanager 8032
    exec yarn nodemanager
    ;;
  bash)
    exec bash
    ;;
  *)
    echo "Unknown HADOOP_ROLE: ${ROLE}" >&2
    exit 1
    ;;
esac
