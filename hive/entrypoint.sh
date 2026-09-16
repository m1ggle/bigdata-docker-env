#!/bin/bash
set -e

ROLE="${HIVE_ROLE:-hiveserver2}"
HIVE_HOME=/opt/hive
export HIVE_HOME
export HADOOP_HOME=/opt/hadoop
export HIVE_CONF_DIR=${HIVE_HOME}/conf
export PATH="$PATH:${HIVE_HOME}/bin:${HADOOP_HOME}/bin"
# Hive scripts default to a 256MB heap, which OOMs the moment a query falls
# back to the local MapReduce runner (e.g. ORDER BY without FETCH conversion).
export HADOOP_HEAPSIZE=${HADOOP_HEAPSIZE:-1024}

# ---------------------------------------------------------------------------
# Render hive-site.xml: inject DB password from env (keeps secrets out of git)
# ---------------------------------------------------------------------------
SITE="${HIVE_CONF_DIR}/hive-site.xml"
if [ -n "${HIVE_DB_PASS}" ]; then
  sed -i "s|__HIVE_DB_PASS__|${HIVE_DB_PASS}|g" "${SITE}"
fi

# ---------------------------------------------------------------------------
# TCP port probe that does NOT depend on external tools (uses bash /dev/tcp,
# falling back to nc only if it happens to be installed).
# ---------------------------------------------------------------------------
wait_for() {
  local host="$1" port="$2"
  echo ">>> waiting for ${host}:${port} ..."
  if command -v nc >/dev/null 2>&1; then
    until nc -z "${host}" "${port}"; do sleep 3; done
  else
    until (exec 3<>"/dev/tcp/${host}/${port}") 2>/dev/null; do sleep 3; done
    exec 3>&- 2>/dev/null || true
  fi
  echo ">>> ${host}:${port} is up"
}

wait_for postgres 5432
wait_for namenode 9000

# ---------------------------------------------------------------------------
# Initialise the metastore schema once (idempotent guard on the version table)
# ---------------------------------------------------------------------------
init_schema() {
  echo ">>> Initialising Hive metastore schema (if needed)"
  schematool -dbType postgres -info >/dev/null 2>&1 && {
    echo ">>> schema already present"; return 0;
  } || true
  schematool -dbType postgres -initSchema || \
    schematool -dbType postgres -upgradeSchema || true
}

case "${ROLE}" in
  metastore)
    init_schema
    exec hive --service metastore
    ;;
  hiveserver2)
    wait_for hive-metastore 9083
    exec hive --service hiveserver2
    ;;
  bash)
    exec bash
    ;;
  *)
    echo "Unknown HIVE_ROLE: ${ROLE}" >&2
    exit 1
    ;;
esac
