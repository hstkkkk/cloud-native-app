# Cloud Native Application - 详细部署指南

## 目录
1. [环境准备](#环境准备)
2. [本地开发环境搭建](#本地开发环境搭建)
3. [Docker 容器化部署](#docker-容器化部署)
4. [Kubernetes 集群部署](#kubernetes-集群部署)
5. [Jenkins CI/CD 配置](#jenkins-cicd-配置)
6. [监控系统配置](#监控系统配置)
7. [性能测试与验证](#性能测试与验证)
8. [故障排查指南](#故障排查指南)

## 环境准备

### 软件依赖版本
| 软件 | 最低版本 | 推荐版本 | 说明 |
|------|----------|----------|------|
| Java | 17 | 17+ | 运行时环境 |
| Maven | 3.6.0 | 3.8+ | 构建工具 |
| Docker | 20.10 | 最新版 | 容器运行时 |
| Kubernetes | 1.20 | 1.25+ | 容器编排 |
| Redis | 6.0 | 最新版 | 分布式限流 |
| Jenkins | 2.400 | 最新版 | CI/CD |
| Prometheus | 2.30 | 最新版 | 监控 |
| Grafana | 8.0 | 最新版 | 可视化 |

### 硬件要求
- **内存**: 最少 4GB，推荐 8GB+
- **CPU**: 最少 2 核，推荐 4 核+
- **磁盘**: 最少 20GB 可用空间

## 本地开发环境搭建

### 1. 安装 Java 17
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install openjdk-17-jdk

# CentOS/RHEL
sudo yum install java-17-openjdk-devel

# 验证安装
java -version
javac -version
```

### 2. 安装 Maven
```bash
# Ubuntu/Debian
sudo apt install maven

# CentOS/RHEL
sudo yum install maven

# 或者下载手动安装
wget https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
tar -xzf apache-maven-3.9.5-bin.tar.gz
sudo mv apache-maven-3.9.5 /opt/maven
echo 'export PATH=/opt/maven/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 验证安装
mvn -version
```

### 3. 克隆并构建项目
```bash
# 克隆项目
git clone <repository-url>
cd cloud-native-app

# 使用 Maven Wrapper (推荐)
./mvnw clean compile
./mvnw test
./mvnw package

# 或使用系统 Maven
mvn clean package
```

### 4. 启动应用
```bash
# 方式1: 使用 Maven 插件
./mvnw spring-boot:run

# 方式2: 直接运行 JAR
java -jar target/cloud-native-app-1.0.0.jar

# 方式3: 开发模式 (热重载)
./mvnw spring-boot:run -Dspring-boot.run.jvmArguments="-Dspring.devtools.restart.enabled=true"
```

### 5. 验证部署
```bash
# 健康检查
curl http://localhost:8080/api/health

# 测试接口
curl http://localhost:8080/api/hello

# 查看监控指标
curl http://localhost:8080/actuator/prometheus

# 查看应用信息
curl http://localhost:8080/actuator/info
```

## Docker 容器化部署

### 1. 安装 Docker
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 验证安装
docker --version
docker run hello-world
```

### 2. 构建镜像
```bash
# 构建应用镜像
docker build -t cloud-native-app:latest .

# 查看镜像
docker images | grep cloud-native-app

# 检查镜像层
docker history cloud-native-app:latest
```

### 3. 运行容器
```bash
# 基础运行
docker run -p 8080:8080 cloud-native-app:latest

# 后台运行
docker run -d -p 8080:8080 --name cloud-app cloud-native-app:latest

# 带环境变量
docker run -d -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e JAVA_OPTS="-Xmx512m" \
  --name cloud-app \
  cloud-native-app:latest

# 查看容器状态
docker ps
docker logs cloud-app
```

### 4. Docker Compose 部署 (含 Redis)
```bash
# 创建 docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - SPRING_REDIS_HOST=redis
    depends_on:
      - redis
    restart: unless-stopped
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    restart: unless-stopped
    command: redis-server --maxmemory 100mb --maxmemory-policy allkeys-lru
EOF

# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps
docker-compose logs -f app
```

## Kubernetes 集群部署

### 1. 安装 Kubernetes

#### minikube (本地开发)
```bash
# 安装 minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 启动集群
minikube start --memory=4096 --cpus=2

# 启用插件
minikube addons enable metrics-server
minikube addons enable ingress
```

#### k3s (轻量级生产)
```bash
# 安装 k3s
curl -sfL https://get.k3s.io | sh -

# 配置 kubectl
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config
```

### 2. 验证集群
```bash
# 检查节点
kubectl get nodes

# 检查系统 Pods
kubectl get pods -n kube-system

# 检查资源
kubectl top nodes
```

### 3. 部署应用

#### 创建命名空间
```bash
kubectl create namespace cloud-native
kubectl config set-context --current --namespace=cloud-native
```

#### 部署 Redis (可选)
```bash
# 部署 Redis
kubectl apply -f k8s/redis.yaml

# 验证 Redis
kubectl get pods -l app=redis
kubectl logs -l app=redis
```

#### 部署应用
```bash
# 部署应用
kubectl apply -f k8s/deployment.yaml

# 查看部署状态
kubectl get deployments
kubectl get pods
kubectl get services

# 查看 Pod 详情
kubectl describe pod <pod-name>
kubectl logs -f <pod-name>
```

### 4. 配置监控
```bash
# 部署 ServiceMonitor (需要 Prometheus Operator)
kubectl apply -f k8s/servicemonitor.yaml

# 配置 HPA
kubectl apply -f k8s/hpa.yaml

# 查看 HPA 状态
kubectl get hpa
kubectl describe hpa cloud-native-app
```

### 5. 测试访问
```bash
# 端口转发 (开发测试)
kubectl port-forward service/cloud-native-app 8080:8080

# 或者获取 Service 地址
kubectl get service cloud-native-app

# minikube 访问
minikube service cloud-native-app --url

# 测试接口
curl $(minikube service cloud-native-app --url)/api/hello
```

## Jenkins CI/CD 配置

### 1. 安装 Jenkins
```bash
# 使用 Docker 安装
docker run -d -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  --name jenkins \
  jenkins/jenkins:lts

# 获取初始密码
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 2. 配置 Jenkins

#### 安装必要插件
在 Jenkins 管理界面安装以下插件：
- Pipeline
- Git
- Docker Pipeline
- Kubernetes
- Prometheus metrics
- BlueOcean (可选)

#### 配置凭据
1. 添加 Git 仓库凭据
2. 添加 Docker Registry 凭据
3. 添加 Kubernetes 集群凭据

### 3. 创建 Pipeline

#### CI Pipeline
```bash
# 创建新的 Pipeline 任务
# 选择 "Pipeline script from SCM"
# SCM: Git
# Repository URL: <your-repo-url>
# Script Path: Jenkinsfile
```

#### CD Pipeline
```bash
# 创建参数化 Pipeline
# 选择 "Pipeline script from SCM"
# Script Path: jenkins/Jenkinsfile-CD
# 添加参数:
#   - ENVIRONMENT (choice): dev,test,prod
#   - REPLICAS (string): 2
#   - ENABLE_REDIS (boolean): true
```

### 4. 执行 Pipeline
```bash
# 手动触发构建
# 或配置 Webhook 自动触发
# 查看构建日志和结果
```

## 监控系统配置

### 1. 安装 Prometheus

#### 使用 Helm (推荐)
```bash
# 安装 Helm
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/

# 添加 Prometheus 仓库
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 安装 Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
```

#### 验证安装
```bash
kubectl get pods -n monitoring
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

### 2. 配置 Grafana

#### 访问 Grafana
```bash
# 获取默认密码
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# 端口转发
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# 访问: http://localhost:3000
# 用户名: admin
# 密码: (上面获取的密码)
```

#### 导入仪表板
1. 登录 Grafana
2. 点击 "+" -> "Import"
3. 上传 `monitoring/grafana-dashboard.json`
4. 配置数据源为 Prometheus

### 3. 配置告警 (可选)
```bash
# 创建告警规则
kubectl apply -f - << 'EOF'
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: cloud-native-app-alerts
  namespace: cloud-native
spec:
  groups:
  - name: cloud-native-app
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High error rate detected"
        description: "Error rate is above 10% for 5 minutes"
    
    - alert: HighLatency
      expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High latency detected"
        description: "95th percentile latency is above 1 second"
EOF
```

## 性能测试与验证

### 1. 基础功能测试
```bash
# API 功能测试
curl -X GET http://localhost:8080/api/hello
curl -X GET http://localhost:8080/api/health

# 限流测试
for i in {1..15}; do
  curl -w "\n%{http_code} - %{time_total}s\n" http://localhost:8080/api/hello
  sleep 1
done
```

### 2. 负载测试
```bash
# 使用项目自带脚本
./scripts/load-test.sh -u http://localhost:8080 -r 100 -c 10 -t 60

# 使用 Apache Bench
ab -n 1000 -c 10 http://localhost:8080/api/hello

# 使用 wrk
wrk -t12 -c400 -d30s http://localhost:8080/api/hello
```

### 3. 高级性能测试
```bash
# 使用 Python 脚本
python scripts/advanced_load_test.py

# 自定义参数
python scripts/advanced_load_test.py \
  --url http://localhost:8080 \
  --requests 1000 \
  --concurrency 20 \
  --duration 300
```

### 4. 自动扩容测试
```bash
# 生成持续负载
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh

# 在容器内执行
while true; do wget -q -O- http://cloud-native-app:8080/api/hello; done

# 观察扩容
kubectl get hpa -w
kubectl get pods -w
```

## 故障排查指南

### 应用启动问题

#### 问题: 应用无法启动
```bash
# 检查 Java 版本
java -version

# 检查端口占用
netstat -tlnp | grep 8080
lsof -i :8080

# 检查应用日志
tail -f logs/spring.log
journalctl -u cloud-native-app -f
```

#### 问题: 内存不足
```bash
# 调整 JVM 参数
export JAVA_OPTS="-Xmx512m -Xms256m"
java $JAVA_OPTS -jar target/cloud-native-app-1.0.0.jar

# 监控内存使用
free -h
ps aux | grep java
```

### 容器问题

#### 问题: 容器无法启动
```bash
# 检查镜像
docker images
docker inspect cloud-native-app:latest

# 查看容器日志
docker logs <container-id>

# 进入容器调试
docker exec -it <container-id> /bin/bash
```

#### 问题: 容器内存溢出
```bash
# 增加容器内存限制
docker run -m 1g cloud-native-app:latest

# 或者调整 JVM 参数
docker run -e JAVA_OPTS="-Xmx512m" cloud-native-app:latest
```

### Kubernetes 问题

#### 问题: Pod 无法调度
```bash
# 检查节点资源
kubectl top nodes
kubectl describe node <node-name>

# 检查 Pod 状态
kubectl get pods
kubectl describe pod <pod-name>

# 查看事件
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### 问题: 服务无法访问
```bash
# 检查 Service
kubectl get svc
kubectl describe svc cloud-native-app

# 检查 Endpoints
kubectl get endpoints

# 测试网络连通性
kubectl run debug --image=nicolaka/netshoot -it --rm -- /bin/bash
```

### 监控问题

#### 问题: 指标无法采集
```bash
# 检查 Prometheus 配置
kubectl get servicemonitor
kubectl describe servicemonitor cloud-native-app

# 检查 Prometheus targets
# 访问 Prometheus UI -> Status -> Targets

# 检查应用指标端点
curl http://localhost:8080/actuator/prometheus
```

#### 问题: Grafana 无法显示数据
```bash
# 检查数据源配置
# 验证 Prometheus 连接
# 检查查询语句
# 查看 Grafana 日志
kubectl logs -n monitoring deployment/prometheus-grafana
```

### 性能问题

#### 问题: 响应时间过长
```bash
# 分析应用性能
jstack <pid>
jstat -gc <pid> 1s

# 检查数据库连接
# 检查外部服务调用
# 分析慢查询日志
```

#### 问题: 内存泄漏
```bash
# 生成堆转储
jmap -dump:format=b,file=heapdump.hprof <pid>

# 分析 GC 日志
-XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps

# 使用内存分析工具
# - Eclipse MAT
# - VisualVM
# - JProfiler
```

## 最佳实践

### 开发阶段
1. 使用 Maven Wrapper 确保构建一致性
2. 编写充分的单元测试
3. 配置代码质量检查工具
4. 使用开发配置文件

### 构建阶段
1. 使用多阶段 Docker 构建
2. 优化镜像层缓存
3. 配置 .dockerignore
4. 扫描镜像安全漏洞

### 部署阶段
1. 使用命名空间隔离环境
2. 配置资源限制和请求
3. 设置健康检查探针
4. 使用 ConfigMap 和 Secret

### 运维阶段
1. 配置全面的监控指标
2. 设置合理的告警规则
3. 定期备份配置和数据
4. 制定故障恢复方案

### 安全建议
1. 使用非 root 用户运行应用
2. 定期更新基础镜像
3. 配置网络策略
4. 启用 RBAC 权限控制
5. 加密敏感配置信息

通过遵循以上指南，可以成功部署和运维云原生应用，实现高可用、可扩展、可观测的服务。
