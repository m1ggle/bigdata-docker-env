#!/bin/bash
# ---------------------------------------------------------------------------
# Creates a Kafka topic for demo / streaming tests.
# Execute with:  docker exec kafka /init/20-kafka-init.sh
# ---------------------------------------------------------------------------
set -e

BOOTSTRAP="kafka:9092"

echo ">>> creating demo topic: hudi-demo"
/opt/kafka/bin/kafka-topics.sh --bootstrap-server ${BOOTSTRAP} \
  --create --if-not-exists \
  --topic hudi-demo \
  --partitions 3 \
  --replication-factor 1

echo ">>> current topics"
/opt/kafka/bin/kafka-topics.sh --bootstrap-server ${BOOTSTRAP} --list
