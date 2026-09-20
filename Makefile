# =============================================================================
#  大数据开发环境 - 常用命令
# =============================================================================
COMPOSE := docker compose

.PHONY: help up down clean ps logs init build restart hdfs-test hive-test spark-test flink-test kafka-test ds-test

help:
	@echo "可用命令:"
	@echo "  make up         构建并后台启动全部服务"
	@echo "  make build      仅构建镜像"
	@echo "  make down       停止并删除容器(保留数据卷)"
	@echo "  make clean      停止并删除容器 + 数据卷"
	@echo "  make ps         查看服务状态"
	@echo "  make logs       跟踪全部日志"
	@echo "  make init       初始化 HDFS 目录 + Kafka topic"
	@echo "  make restart    重启全部服务"
	@echo "  make hdfs-test  测试 HDFS"
	@echo "  make hive-test  测试 Hive(Beeline)"
	@echo "  make spark-test 测试 Spark + Hudi 示例"
	@echo "  make flink-test 测试 Flink"
	@echo "  make kafka-test 列出 Kafka topics"
	@echo "  make ds-test    测试 DolphinScheduler Web UI 端口"

up:
	$(COMPOSE) up -d --build
	@echo ">>> 等待服务就绪后执行: make init"

build:
	$(COMPOSE) build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

init:
	@echo ">>> 初始化 HDFS 目录"
	docker exec namenode bash /init/10-hdfs-init.sh
	@echo ">>> 初始化 Kafka topic"
	docker exec kafka bash /init/20-kafka-init.sh

hdfs-test:
	docker exec namenode hdfs dfs -ls /

hive-test:
	docker exec -it hive-server beeline -u 'jdbc:hive2://hive-server:10000/' -e 'show databases;'

# 把示例 SQL 复制进 spark-master 再执行
spark-test:
	docker cp sql/hudi-demo.sql spark-master:/opt/spark/hudi-demo.sql
	docker exec -it spark-master /opt/spark/bin/spark-sql \
	  --conf 'spark.serializer=org.apache.spark.serializer.KryoSerializer' \
	  --conf 'spark.sql.extensions=org.apache.spark.sql.hudi.HoodieSparkSessionExtension' \
	  --conf 'spark.sql.catalog.spark_catalog=org.apache.spark.sql.hudi.catalog.HoodieCatalog' \
	  -f /opt/spark/hudi-demo.sql

flink-test:
	docker exec -it flink-jobmanager flink list

kafka-test:
	docker exec -it kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --list

ds-test:
	docker exec dolphinscheduler bash -c 'timeout 5 bash -c "echo > /dev/tcp/localhost/12345" && echo "DolphinScheduler UI is up: http://localhost:12345/dolphinscheduler/ui"'
