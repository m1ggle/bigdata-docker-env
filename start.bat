@echo off
setlocal
cd /d "%~dp0"

echo == Step 1/4: Check Docker ==
where docker >nul 2>nul
if errorlevel 1 (
    echo [ERROR] docker command not found.
    echo Please install and start Docker Desktop: https://www.docker.com/products/docker-desktop/
    pause
    exit /b 1
)
docker version >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)
echo Docker is ready.

echo == Step 2/4: Prepare .env ==
if not exist ".env" (
    copy ".env.example" ".env" >nul
    echo Created .env from .env.example
) else (
    echo .env already exists, skipping.
)

echo == Step 3/4: Build and start all services ==
docker compose up -d --build
if errorlevel 1 (
    echo [ERROR] docker compose failed.
    pause
    exit /b 1
)

echo == Step 4/4: Wait for services and initialize ==
echo Waiting 60 seconds for NameNode and Kafka to start...
timeout /t 60 /nobreak >nul

echo Initializing HDFS directories...
docker exec namenode bash /init/10-hdfs-init.sh
echo Initializing Kafka topic...
docker exec kafka bash /init/20-kafka-init.sh

echo.
echo Done! Open these in your browser:
echo   HDFS NameNode        http://localhost:9870
echo   YARN ResourceManager http://localhost:8088
echo   Spark Master         http://localhost:8080
echo   Spark History        http://localhost:18080
echo   Flink Dashboard      http://localhost:8082
echo   HiveServer2          http://localhost:10002
echo.
echo Stop:  docker compose down
echo Clean: docker compose down -v
pause
endlocal
