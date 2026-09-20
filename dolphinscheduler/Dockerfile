# =============================================================================
#  DolphinScheduler 3.2.2 Standalone + docker CLI
#  在官方 standalone 镜像基础上加装 docker 命令行, 配合 compose 中挂载的
#  /var/run/docker.sock, Shell 任务可直接 `docker exec spark-master ...`
#  调度本环境里的 Spark / Flink / Hive 作业。
# =============================================================================
FROM docker.1ms.run/apache/dolphinscheduler-standalone-server:3.2.2

ARG DOCKER_CLI_VERSION=27.3.1

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL --retry 3 \
      "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz" \
      -o /tmp/docker-cli.tgz \
 && tar -xzf /tmp/docker-cli.tgz -C /tmp \
 && mv /tmp/docker/docker /usr/local/bin/docker \
 && chmod +x /usr/local/bin/docker \
 && rm -rf /tmp/docker /tmp/docker-cli.tgz
