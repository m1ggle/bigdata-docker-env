#!/usr/bin/env bash
set -e

ROLE="${SPARK_ROLE:-master}"
SPARK_HOME=/opt/spark
export SPARK_HOME
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export PATH="$PATH:${SPARK_HOME}/bin:${SPARK_HOME}/sbin"

# Connect Spark SQL to the Hive metastore (so spark-sql sees Hive tables)
export SPARK_DIST_CLASSPATH="$(hadoop classpath 2>/dev/null || true)"

wait_for() {
  local host="$1" port="$2"
  echo ">>> waiting for ${host}:${port} ..."
  until nc -z "${host}" "${port}"; do sleep 3; done
  echo ">>> ${host}:${port} is up"
}

case "${ROLE}" in
  master)
    wait_for namenode 9000
    exec ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.master.Master \
        --host spark-master --port 7077 --webui-port 8080
    ;;
  worker)
    wait_for spark-master 7077
    exec ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.worker.Worker \
        --webui-port 8081 spark://spark-master:7077
    ;;
  history)
    exec ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.history.HistoryServer
    ;;
  thrift)
    wait_for hive-metastore 9083
    exec ${SPARK_HOME}/sbin/start-thriftserver.sh \
        --hiveconf hive.server2.thrift.port=10000 \
        --master spark://spark-master:7077
    ;;
  bash)
    exec bash
    ;;
  *)
    echo "Unknown SPARK_ROLE: ${ROLE}" >&2
    exit 1
    ;;
esac
