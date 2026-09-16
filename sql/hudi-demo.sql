-- =============================================================================
--  Hudi + Spark SQL 示例 (COW 表)
--  用法:
--    docker exec -it spark-master /opt/spark/bin/spark-sql \
--      --jars /opt/spark/jars/hudi-spark3.4-bundle_2.12-0.14.1.jar \
--      --conf 'spark.serializer=org.apache.spark.serializer.KryoSerializer' \
--      --conf 'spark.sql.extensions=org.apache.spark.sql.hudi.HoodieSparkSessionExtension' \
--      --conf 'spark.sql.catalog.spark_catalog=org.apache.spark.sql.hudi.catalog.HoodieCatalog' \
--      -f /opt/spark/sql/hudi-demo.sql
-- =============================================================================

-- 0) 关闭 Hudi 元数据表 (metadata table)。
--    hudi 0.14.1 bundle 内置的 HBase 编译自 Hadoop 2 的方法签名, 在 Hadoop 3.3.6 上
--    读元数据表 HFile 时报 NoSuchMethodError: HdfsDataInputStream.getReadStatistics
--    且本地 HDFS 用不上元数据表, 直接关闭。
set hoodie.metadata.enable=false;

-- 1) 建一张 Hudi COW 表 (分区表, 记录键 + 预合并键)
CREATE TABLE IF NOT EXISTS hudi_demo.trips (
  id            BIGINT,
  rider         STRING,
  driver        STRING,
  fare          DOUBLE,
  ts            BIGINT,
  `partition`   STRING
)
USING hudi
OPTIONS (
  type                     = 'cow',
  primaryKey               = 'id',
  preCombineField          = 'ts',
  hoodie.metadata.enable   = 'false'
)
PARTITIONED BY (`partition`)
LOCATION 'hdfs://namenode:9000/hudi/trips';

-- 2) 插入数据
INSERT INTO ods.trips SELECT 1, 'alice', 'bob', 12.5, 1000, '2024-01-01';

INSERT INTO hudi_demo.trips
SELECT 2, 'carol', 'dave', 20.0, 1001, '2024-01-01';

-- 3) 增量 upsert (相同的 primaryKey id=1 会被合并)
INSERT INTO hudi_demo.trips
SELECT 1, 'alice', 'eve', 18.0, 1002, '2024-01-01';

-- 4) 查询
SELECT * FROM ods.trips;

-- 5) 按时间点查询 (Hudi time travel)
-- SELECT * FROM hudi_demo.trips TIMESTAMP AS OF '2024-01-01 00:00:00';

-- 6) 更新 / 删除 (Spark SQL MERGE 写法)
-- MERGE INTO hudi_demo.trips AS t
-- USING (SELECT 2 AS id, 'carol2' AS rider, 'dave' AS driver, 25.0 AS fare, 1005 AS ts, '2024-01-01' AS `partition`) AS s
-- ON t.id = s.id
-- WHEN MATCHED THEN UPDATE SET t.fare = s.fare, t.ts = s.ts
-- WHEN NOT MATCHED THEN INSERT *;

-- DELETE FROM hudi_demo.trips WHERE id = 2;

-- 7) 查看 Hudi 表元数据
CALL show_commits('hudi_demo.trips', 5);
CALL show_fsview_all('hudi_demo.trips');
