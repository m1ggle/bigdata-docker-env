# 大数据开发环境（Windows / Docker Desktop 版）

面向 **Windows 10/11 + Docker Desktop（WSL2 后端）** 的一键大数据开发环境，
包含 **Hadoop、Hive、Spark、Flink、Kafka、Hudi、DolphinScheduler**。

> 本工程同样适用于 Linux / macOS，只需把 `.ps1` / `.bat` 换成 `make` 命令即可。

## 组件与版本

| 组件    | 版本            | 说明                                                     |
|---------|-----------------|----------------------------------------------------------|
| Hadoop  | 3.3.6           | HDFS（NameNode/DataNode）+ YARN（ResourceManager/NodeManager） |
| Hive    | 3.1.3           | HiveServer2 + Metastore，元数据存 PostgreSQL             |
| Spark   | 3.4.3           | Master / Worker / History Server，内置 Hudi 0.14.1 与 Kafka Connector |
| Hudi    | 0.14.1          | `hudi-spark3.4-bundle_2.12`（Spark 3.4.x / Scala 2.12）  |
| Flink   | 1.18.1          | JobManager + TaskManager                                |
| Kafka   | 3.7.0           | KRaft 模式（无需 ZooKeeper）                            |
| Postgres| 15              | Hive Metastore + DolphinScheduler 元数据库             |
| DolphinScheduler | 3.2.2 | Standalone 单机版（内置 ZK），元数据存 PostgreSQL，可调度本环境组件 |

## Windows 前置条件

1. **Windows 10 21H2+ / Windows 11**，开启 WSL2：
   管理员 PowerShell 执行
   ```powershell
   wsl --install
   ```
   安装完成后重启电脑。
2. **安装 Docker Desktop for Windows**：https://www.docker.com/products/docker-desktop/
   安装时勾选 *Use WSL 2 instead of Hyper-V*。
3. 启动 Docker Desktop，等待左下角状态变为 **Engine running**。
4. 建议给 Docker Desktop 分配足够内存：*Settings → Resources → Memory* ≥ **8 GB**。
5. 确认命令行可用：
   ```powershell
   docker version
   docker compose version
   ```

> **WSL2 内存注意**：整套环境约需 10~14 GB 内存（含 DolphinScheduler 约 +2 GB）。
> 若主机内存不足，可在
> `hadoop/conf/yarn-site.xml`、`spark/conf/spark-defaults.conf`、
> `flink/conf/flink-conf.yaml` 下调各组件内存。

## 快速开始（Windows）

### 方式一：一键脚本（推荐）

在工程根目录双击 **`start.bat`**，或在 PowerShell 中执行：

```powershell
cd 你的工程目录
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

脚本会自动：检查 Docker → 生成 `.env` → 构建并启动 → 等待就绪 → 初始化 HDFS 目录与 Kafka topic。

> 首次构建需下载 Hadoop / Spark 发行包与 Hudi jar，约 **10~20 分钟**（取决于网络），请耐心等待。

### 镜像加速（docker.1ms.run）

所有**从 Docker Hub 拉取**的镜像都已加上国内镜像前缀 `docker.1ms.run`：

| 原始镜像 | 替换后地址 |
|----------|------------|
| `postgres:15` | `docker.1ms.run/postgres:15` |
| `flink:1.18.1-scala_2.12-java8` | `docker.1ms.run/flink:1.18.1-scala_2.12-java8` |
| `apache/kafka:3.7.0` | `docker.1ms.run/apache/kafka:3.7.0` |
| `apache/dolphinscheduler-standalone-server:3.2.2` | `docker.1ms.run/apache/dolphinscheduler-standalone-server:3.2.2` |
| `apache/dolphinscheduler-tools:3.2.2` | `docker.1ms.run/apache/dolphinscheduler-tools:3.2.2` |
| `eclipse-temurin:8-jdk-jammy`（Hadoop/Spark 基础镜像） | `docker.1ms.run/eclipse-temurin:8-jdk-jammy`（DolphinScheduler 官方基础镜像 `eclipse-temurin:8-jdk` 走 Docker Hub，国内网络通常可直连，故未替换） |
| `apache/hive:3.1.3`（Hive 基础镜像） | `docker.1ms.run/apache/hive:3.1.3` |

> 说明：`bigdata/hadoop`、`bigdata/hive`、`bigdata/spark`、`bigdata/dolphinscheduler`
> 是本工程用 Dockerfile **本地构建**的镜像
> （由 `docker compose build` 生成，不经过 registry 拉取），因此不加前缀；它们的基础镜像
> （eclipse-temurin / apache/hive）已使用镜像加速。

### 方式二：手动命令

```powershell
# 1. 生成环境变量文件
Copy-Item .env.example .env
# 按需编辑 .env 修改密码

# 2. 构建并启动
docker compose up -d --build

# 3. 等待约 60 秒后初始化
docker exec namenode bash /init/10-hdfs-init.sh
docker exec kafka bash /init/20-kafka-init.sh

# 4. 查看状态
docker compose ps
```

### 停止 / 清理

```powershell
docker compose down          # 停止(保留数据)
docker compose down -v       # 停止并删除数据卷
# 或
powershell -ExecutionPolicy Bypass -File .\stop.ps1
powershell -ExecutionPolicy Bypass -File .\stop.ps1 -Clean
```

## 各服务 Web UI / 端口（浏览器直接打开）

| 服务                 | 地址                          | 说明                     |
|----------------------|-------------------------------|--------------------------|
| HDFS NameNode        | http://localhost:9870         | HDFS 文件浏览            |
| HDFS DataNode        | http://localhost:9864         | DataNode 状态            |
| YARN ResourceManager | http://localhost:8088         | YARN 应用                |
| NodeManager          | http://localhost:8042         | 节点管理                 |
| Spark Master         | http://localhost:8080         | Spark 集群               |
| Spark Worker         | http://localhost:8081         | Worker                   |
| Spark History        | http://localhost:18080        | 作业历史                 |
| Flink                | http://localhost:8082         | Flink Dashboard          |
| HiveServer2          | http://localhost:10002        | HiveServer2 Web          |
| Kafka                | localhost:9092                | Broker（客户端接入）     |
| PostgreSQL           | localhost:5432                | 元数据库                 |
| DolphinScheduler     | http://localhost:12345/dolphinscheduler/ui | 任务调度平台（见下文） |

## JDBC / 客户端连接信息

> **重要**：宿主机连 Hive 不要用 `localhost:10000`。若本机装了深信服等安全软件
> （`SangforPromoteService` 会抢占 `127.0.0.1:10000`），JDBC 握手会失败并报
> `Invalid status 16`。改用**局域网 IP**（`ipconfig` 查看，如 `10.x.x.x`）即可。
> 其他端口（5432/9083/9092 等）不受影响。

### Hive（HiveServer2 3.1.3，无认证）

| 场景                     | 连接信息                                                       |
|--------------------------|----------------------------------------------------------------|
| DataGrip / DBeaver 等宿主机工具 | `jdbc:hive2://<本机局域网IP>:10000/default`（勿用 localhost）  |
| 容器网络内                | `jdbc:hive2://hive-server:10000/default`                       |
| beeline                  | `docker exec -it hive-server beeline -u "jdbc:hive2://hive-server:10000/"` |
| Metastore Thrift         | `thrift://hive-metastore:9083`（宿主机 `localhost:9083` 已映射）|
| JDBC 驱动                 | Apache Hive 3.1.3 standalone（与服务端版本一致最稳）           |

用户名任意（如 `root`），密码留空。

### PostgreSQL 15（Hive / DolphinScheduler 元数据库）

| 场景     | 连接信息                                        |
|----------|-------------------------------------------------|
| JDBC     | `jdbc:postgresql://localhost:5432/metastore`   |
| 超级用户 | `admin` / `admin123`（同 `.env`）               |
| 业务用户 | `hive` / `hive123`（metastore 库属主）          |
| DS 元数据 | 库 `dolphinscheduler`，用户 `dolphinscheduler` / `.env` 里的 `DS_DB_PASS` |

### HDFS（Hadoop 3.3.6）

| 场景            | 连接信息                                                            |
|-----------------|---------------------------------------------------------------------|
| WebHDFS REST    | `http://localhost:9870/webhdfs/v1/<路径>?op=LISTSTATUS&user.name=root` |
| RPC（容器网络内）| `hdfs://namenode:9000`                                              |
| 命令行          | `docker exec namenode hdfs dfs -ls /`                               |
| 数仓目录        | `/warehouse/tablespace/managed/hive`                                |

### Spark 3.4.3（+ Hudi 0.14.1）

| 场景             | 连接信息                                                    |
|------------------|-------------------------------------------------------------|
| Master RPC（容器网络内） | `spark://spark-master:7077`                          |
| 提交作业         | `docker exec spark-master spark-submit --master spark://spark-master:7077 ...` |

### Flink 1.18.1

| 场景             | 连接信息                                   |
|------------------|--------------------------------------------|
| JobManager RPC（容器网络内） | `flink-jobmanager:6123`          |
| CLI             | `docker exec flink-jobmanager flink ...`  |

### Kafka 3.7.0（KRaft）

| 场景            | 连接信息                                                     |
|-----------------|--------------------------------------------------------------|
| 容器网络内      | `kafka:9092`                                                 |
| 宿主机客户端    | TCP `localhost:9092` 可通，但 advertised listener 为 `kafka:9092`，需在 `C:\Windows\System32\drivers\etc\hosts` 添加 `127.0.0.1 kafka` |
| CLI             | `docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --list` |

### DolphinScheduler 3.2.2（Standalone）

| 场景             | 信息                                                          |
|------------------|---------------------------------------------------------------|
| Web UI           | `http://localhost:12345/dolphinscheduler/ui`                  |
| 默认账号         | `admin` / `dolphinscheduler123`（登录后请改密码）             |
| 元数据库         | postgres 容器 `dolphinscheduler` 库（自动创建并建表）         |
| REST API         | `http://localhost:12345/dolphinscheduler`                     |
| 容器网络内地址   | `dolphinscheduler:12345`；Hive 数据源填 `hive-server:10000`  |

**零手工初始化**：`ds-db-init`（幂等建库/角色）→ `ds-schema-init`
（官方 `upgrade-schema.sh` 建表）→ `dolphinscheduler` 按依赖顺序自动执行，
即使 PostgreSQL 数据卷早于 DolphinScheduler 存在也能正常补齐。

**调度本环境组件**：standalone 镜像内置 ZooKeeper（无需外部注册中心）；
`dolphinscheduler` 容器已挂载 `docker.sock` 并安装了 docker CLI（见
`dolphinscheduler/Dockerfile`），因此在 **Shell 任务** 里可以直接提交作业：

```bash
# 示例：跑一个 Spark 作业（容器名即本环境的 spark-master）
docker exec spark-master spark-submit --master spark://spark-master:7077 \
  --class org.apache.spark.examples.SparkPi /opt/spark/examples/jars/spark-examples_2.12-3.4.3.jar 10
```

同理可写 `docker exec hive-server beeline -u "jdbc:hive2://hive-server:10000/" -e "..."`
或 `docker exec flink-jobmanager flink run ...`。Hive/Spark 的 SQL 类任务也可
用 DS 自带的 Hive / Spark 数据源 + SQL 节点（ JDBC 走容器网络）。

> 注意：挂载 `docker.sock` 等于给该容器宿主机 Docker 的控制权，仅限本地开发环境。
> 另外 DS 的 Spark/Flink 原生任务类型需要 worker 内有对应客户端，本环境推荐走
> Shell + `docker exec` 方式；若坚持使用原生节点，可自建镜像把 spark/flink 客户端 COPY 进去。

## 常用操作（在 PowerShell / CMD 中执行）

### HDFS
```powershell
docker exec -it namenode hdfs dfs -ls /
docker exec -it namenode hdfs dfs -mkdir -p /test
```

### Hive（Beeline）
```powershell
docker exec -it hive-server beeline -u "jdbc:hive2://hive-server:10000/"
```
> 注意：PowerShell 中 JDBC URL 建议用双引号包裹，避免解析问题。

### Spark SQL（读写 Hive 元数据）
```powershell
docker exec -it spark-master /opt/spark/bin/spark-sql
```

### Spark + Hudi 示例
```powershell
docker cp sql/hudi-demo.sql spark-master:/opt/spark/hudi-demo.sql
docker exec -it spark-master /opt/spark/bin/spark-sql `
  --conf "spark.serializer=org.apache.spark.serializer.KryoSerializer" `
  --conf "spark.sql.extensions=org.apache.spark.sql.hudi.HoodieSparkSessionExtension" `
  --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.hudi.catalog.HoodieCatalog" `
  -f /opt/spark/hudi-demo.sql
```
> PowerShell 中多行命令用反引号 `` ` `` 续行；CMD 中用 `^`。

> **Hudi 写入/查询前必须先执行** `set hoodie.metadata.enable=false;`（demo 脚本已内置）。
> 原因见下方 FAQ「NoSuchMethodError: HdfsDataInputStream.getReadStatistics」。

### Flink
```powershell
docker exec -it flink-jobmanager flink list
docker exec -it flink-jobmanager flink run -d /opt/flink/examples/streaming/WordCount.jar
```

### Kafka
```powershell
# 生产者
docker exec -it kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:9092 --topic hudi-demo
# 消费者(另开一个窗口)
docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic hudi-demo --from-beginning
```

## 构建 / 部署常见问题

- **`hive` 镜像构建报 `Syntax error: redirection unexpected`（exit code 2）**
  原因是 `apache/hive` 基础镜像的 `RUN` 由 `/bin/sh`（dash）执行，不支持 bash 专有的 here-string `<<<`。
  已修复为纯 POSIX 写法。
- **`hive` 镜像构建报 `wget/curl: command not found`（exit code 127）**
  原因是 `apache/hive:3.1.3` 基础镜像极简，未内置 `curl`/`wget`、包管理器也不可用，无法在镜像内下载 JDBC 驱动。
  已改为**多阶段构建**：用一个 Ubuntu 基础镜像下载 PostgreSQL JDBC 驱动，
  再 `COPY --from` 复制进 Hive 镜像，完全不依赖基础镜像内的下载工具。
- **拉取镜像慢 / 超时**
  所有外部镜像均已使用 `docker.1ms.run` 前缀；若仍慢，可在 Docker Desktop → Settings → Docker Engine 配置镜像加速。
- **构建时卡在下载 Hadoop / Spark（`archive.apache.org` 卡住不动）**
  已改为**国内镜像优先 + 多源回退**并配置超时/重试：
  - Hadoop 3.3.6：阿里云 → 清华 → 华为云 → 官方 archive
  - Spark 3.4.3：华为云 → 阿里云 → 清华 → 官方 archive（注意 Spark 3.4.3 已从阿里/清华下架，仅华为云有）
  - Spark 内依赖 jar：阿里云 Maven → Maven 中央仓库
  若某镜像源失效，脚本会自动尝试下一个，全部失败才报错退出。
- **Spark 3.4.3 镜像源 404**
  Spark 3.4.3 已从阿里云 / 清华的 apache 镜像中移除，本工程默认使用**华为云**镜像下载，无需手动改。

- **`dependency namenode failed to start` / namenode 一直 unhealthy**
  两个已修复的常见原因：
  1. NameNode 的 HTTP 地址原先绑定到容器主机名（只监听容器 IP），导致健康检查
     `curl localhost:9870` 访问 127.0.0.1 被拒绝 → 判定 unhealthy → 依赖它的容器全部失败。
     现已在 `hadoop/conf/hdfs-site.xml` 中将 `dfs.namenode.http-address` 绑定到 `0.0.0.0`，
     并在 compose 健康检查中加入 `--max-time` 与 `start_period: 120s`。
     **注意**：`dfs.namenode.rpc-address` 必须保持 `namenode:9000`，不能改成 `0.0.0.0`
     （原因见下一条）。
  2. **上一次构建失败残留的半格式化数据卷**。若曾中途失败，请彻底清卷重建：
     ```cmd
     docker compose down -v
     docker compose up -d --build
     ```
     仅在首次全新启动时 NameNode 才会自动格式化；卷被清空后会自动重新格式化。

- **Spark/Hive 写 HDFS 报 `could only be written to 0 of the 1 minReplication nodes` / `There are 0 datanode(s) running`**
  原因：`dfs.namenode.rpc-address` 被设成了 `0.0.0.0:9000`。该属性是**双向**的：
  NameNode 用它绑定监听，**DataNode 也用它作为注册连接地址**。DataNode 连 `0.0.0.0`
  等于连自己的 localhost（容器内无 9000 监听）→ 永远注册不上 → NameNode 视角
  `0 datanode(s) running`，所有需要写数据块的操作全部失败。
  之前没暴露是因为建目录、建库等命名空间操作不需要 DataNode，真正写块时才炸出来。
  已修复：`hadoop/conf/hdfs-site.xml` 中改回 `namenode:9000`，重建镜像后 DataNode
  正常注册（`hdfs dfsadmin -report` 可见 `Live datanodes (1)`）。

- **Hudi 写入/查询报 `NoSuchMethodError: HdfsDataInputStream.getReadStatistics()`**
  原因：`hudi-spark3.4-bundle 0.14.1` 内部 shaded 的 HBase 按旧 Hadoop 方法签名编译，
  在 Hadoop 3.3.6 上读取 Hudi **元数据表（metadata table）** 的 HFile 时触发。
  典型表现：INSERT 数据实际已提交成功，但 commit 后的自动清理（clean）/查询阶段报错，
  最终命令以失败告终。
  解决：关闭元数据表 —— 建表时 OPTIONS 写 `hoodie.metadata.enable='false'`；
  对已启用元数据表的存量表，在会话开头执行 `set hoodie.metadata.enable=false;`
  即可（已验证 INSERT/SELECT 均正常）。本地 HDFS 无需元数据表，无任何损失。

- **Hive 查询 Hudi 表报 `ClassNotFoundException: org.apache.hudi.hadoop.HoodieParquetInputFormat`**
  原因：Hudi 同步到 Hive 的表 INPUTFORMAT 指向 Hudi 类，但 HiveServer2 classpath 里
  没有 Hudi 的 jar。
  已修复：`hive/hudi-hadoop-mr-bundle-0.14.1.jar` 已 COPY 进 `/opt/hive/lib`（该 bundle
  完全 shade 了 parquet/avro/hbase，与 Hive 自带 parquet 1.10 不冲突）。

- **Hive 查询 Hudi 表：简单查询正常，但带 `ORDER BY` 的查询返回重复行（历史版本全部读出）/ 或本地 MR 报 `OutOfMemoryError`**
  原因（两层）：
  1. 带排序/聚合的查询不走 FetchTask 而走本地 MapReduce，Hive 默认的
     `CombineHiveInputFormat` 在 combine splits 时**绕过 Hudi 的 file-slice 过滤**，
     把每个历史版本的数据文件全部读出 → 重复行。
  2. HS2 默认堆只有 256MB，本地 MR 一跑就 OOM。
  已修复：
  1. `hive/conf/hive-site.xml` 中 `hive.input.format` 设为
     `org.apache.hudi.hadoop.hive.HoodieCombineHiveInputFormat`（Hudi 官方推荐，
     对非 Hudi 表行为与默认完全一致）。
  2. `hive/entrypoint.sh` 中 `HADOOP_HEAPSIZE` 默认 1024MB。
  建新 Hudi 表后无需任何手工操作，两种查询路径均正常。

- **`spark-history` 报 `FileNotFoundException: Log directory specified does not exist: hdfs://namenode:9000/spark-logs`**
  Spark History Server 启动时需要 HDFS 上的 `/spark-logs` 目录存在（用于存事件日志）。
  现在新增了一个一次性初始化容器 **`hdfs-init`**，它会在 NameNode 就绪后自动创建
  `/spark-logs`、`/hudi`、`/warehouse/...` 等全部基础目录然后退出；
  `spark-master`、`spark-history`、`hive-metastore` 均通过
  `depends_on: hdfs-init: condition: service_completed_successfully` 等待它成功完成后才启动，
  因此不会再出现目录不存在的问题，也**无需再手动执行 `make init`**。

## Windows 常见问题

- **脚本报 `exec format error` 或 `no such file or directory`**
  多半是 shell 脚本被 Windows 转成了 CRLF 行尾。本工程已附 `.gitattributes` 强制 LF；
  若你手动复制过文件，请确保 `*.sh` 与 `Dockerfile` 为 LF：
  ```powershell
  # 用 VS Code 右下角把 CRLF 改为 LF 后保存；或执行
  git config --global core.autocrlf false
  ```
- **端口被占用**（如 8080/8081/9092）
  可用 `netstat -ano | findstr :8080` 找到占用进程；或修改 `docker-compose.yml` 中
  对应服务的 `宿主机端口:容器端口` 左侧端口。
- **Docker Desktop 内存不足 / 容器反复重启**
  提高 *Settings → Resources → Memory*；或按上文调低各组件内存配置。
- **拉镜像很慢**
  可在 Docker Desktop 中配置国内镜像加速器（*Settings → Docker Engine*）。
- **WSL2 磁盘占用越来越大**
  数据卷存在 WSL2 虚拟磁盘中，执行 `docker compose down -v` 清理后，
  可用 `wsl --shutdown` 释放。
- **DataGrip / DBeaver 连 Hive 报 `Invalid status 16`**
  本机若有深信服等安全软件，其 `SangforPromoteService` 进程会抢占
  `127.0.0.1:10000`，导致 JDBC 的 SASL 握手打到错误进程上。
  排查：`netstat -ano | findstr :10000`，若 `127.0.0.1:10000` 的 PID
  不是 `com.docker.backend`，即被劫持。
  解决（任选其一）：
  1. 连接串改用**本机局域网 IP**（`ipconfig` 查 WLAN IPv4，如 `jdbc:hive2://10.x.x.x:10000/default`）——已验证可用；
  2. 修改 `docker-compose.yml` 中 hive-server 的映射为 `"11000:10000"` 避开；
  3. 停用深信服服务（如公司策略允许）。
  注意局域网 IP 由 DHCP 分配，变化后需更新连接串。
- **HiveServer2 起不来，日志报 `URISyntaxException: Illegal character in hostname ... thrift://hive-metastore.xxx_yyy:9083`**
  原因：Compose 默认网络名为 `<项目名>_<网络名>`，**下划线**会进入容器 DNS
  反向解析出的 FQDN，而 Java URI 解析主机名不允许下划线，导致 HS2 初始化失败。
  已修复：`docker-compose.yml` 中为网络显式指定了 `name: bigdata-net`
  （无下划线）。若自行修改 compose 项目名（`name:`），请确保最终网络名不含下划线。

## 目录结构

```
bigdata-docker-env/
├── docker-compose.yml        # 全部服务编排
├── .env.example / .env       # 环境变量（密码、版本）
├── start.ps1 / start.bat     # Windows 一键启动
├── stop.ps1                  # Windows 停止脚本
├── .gitattributes            # 强制 LF，避免 Windows 行尾问题
├── Makefile                  # Linux/macOS 命令封装
├── hadoop/                   # Hadoop 镜像 + 配置 + entrypoint
├── hive/                     # Hive 镜像 + hive-site.xml + entrypoint
├── spark/                    # Spark 镜像 + 配置 + entrypoint
├── flink/conf/               # flink-conf.yaml
├── dolphinscheduler/         # DS 镜像（standalone + docker CLI）Dockerfile
├── init/                     # 初始化脚本（Postgres / HDFS / Kafka / DS 建库）
└── sql/                      # Hudi 示例 SQL
```

## 说明

- 该环境面向**本地开发/学习**，未启用 Kerberos、HA、安全认证等生产级配置。
- 生产部署请自行补充高可用、权限、监控、资源隔离与密钥管理。
