# Cloud Native Application - 云原生应用实践项目

## 项目概述

本项目基于 Spring Boot 开发了一个完整的云原生应用，集成了限流控制、容器化部署、持续集成/持续部署(CI/CD)、监控指标采集、自动扩容等云原生技术栈实践。

### 技术栈
- **应用框架**: Spring Boot 3.x
- **容器化**: Docker
- **编排部署**: Kubernetes
- **持续集成**: Jenkins
- **限流控制**: Bucket4j + Redis
- **监控指标**: Prometheus + Grafana
- **负载测试**: 自定义脚本 + Apache Bench

### 项目特性
- ✅ REST API 接口 (`/api/hello`, `/api/health`)
- ✅ 分布式限流控制 (本地内存 + Redis)
- ✅ 多阶段 Docker 构建
- ✅ Kubernetes 部署与服务发现
- ✅ Jenkins CI/CD 流水线
- ✅ Prometheus 指标暴露
- ✅ Grafana 可视化监控
- ✅ 水平自动扩容 (HPA)
- ✅ 负载测试与性能验证

## 快速开始

### 前置条件
- Java 17+
- Maven 3.6+
- Docker
- Kubernetes (minikube/k3s)
- Redis (可选，用于分布式限流)

### 本地开发
```bash
# 克隆项目
git clone <repository-url>
cd cloud-native-app

# 编译构建
./mvnw clean package

# 运行应用
./mvnw spring-boot:run

# 测试接口
curl http://localhost:8080/api/hello
curl http://localhost:8080/api/health
```

### 容器化部署
```bash
# 构建镜像
docker build -t cloud-native-app:latest .

# 运行容器
docker run -p 8080:8080 cloud-native-app:latest
```

### Kubernetes 部署
```bash
# 部署 Redis (可选)
kubectl apply -f k8s/redis.yaml

# 部署应用
kubectl apply -f k8s/deployment.yaml

# 配置监控
kubectl apply -f k8s/servicemonitor.yaml

# 配置自动扩容
kubectl apply -f k8s/hpa.yaml
```

## 项目结构

```
cloud-native-app/
├── src/
│   ├── main/java/com/example/demo/
│   │   ├── CloudNativeApplication.java      # 主启动类
│   │   ├── controller/
│   │   │   └── HelloController.java         # REST 控制器
│   │   ├── service/
│   │   │   └── HelloService.java           # 业务服务
│   │   └── config/
│   │       └── RateLimiterConfig.java      # 限流配置
│   ├── main/resources/
│   │   └── application.yml                 # 应用配置
│   └── test/                              # 单元测试
├── k8s/                                   # Kubernetes 配置
│   ├── deployment.yaml                    # 部署配置
│   ├── servicemonitor.yaml               # 监控配置
│   ├── hpa.yaml                          # 自动扩容配置
│   └── redis.yaml                        # Redis 配置
├── jenkins/                              # Jenkins 流水线
│   └── Jenkinsfile-CD                    # CD 流水线
├── monitoring/
│   └── grafana-dashboard.json            # Grafana 仪表板
├── scripts/                              # 测试脚本
│   ├── load-test.sh                      # 负载测试脚本
│   └── advanced_load_test.py             # 高级负载测试
├── Dockerfile                            # Docker 构建文件
├── Jenkinsfile                           # CI 流水线
└── pom.xml                               # Maven 配置
```

## 核心功能详解

### 1. REST API 接口

#### Hello 接口
- **URL**: `GET /api/hello`
- **功能**: 返回简单的问候消息
- **限流**: 每分钟最多 10 次请求
- **响应**: `{"msg": "hello"}`

#### 健康检查接口
- **URL**: `GET /api/health`
- **功能**: 检查应用健康状态
- **响应**: `{"status": "UP"}`

### 2. 限流控制

项目实现了两种限流模式：

#### 本地限流 (默认)
- 使用 Bucket4j 内存限流
- 每个实例独立计算限流

#### 分布式限流 (Redis)
- 基于 Redis 的分布式限流
- 多实例共享限流配额
- 配置: `rate.limiter.type=redis`

### 3. 监控指标

暴露 Prometheus 格式监控指标：
- **应用指标**: QPS、响应时间、错误率
- **JVM 指标**: 内存使用、GC 情况、线程数
- **系统指标**: CPU、磁盘、网络
- **限流指标**: 请求通过/拒绝数量

访问 `http://localhost:8080/actuator/prometheus` 查看指标。

### 4. 容器化

使用多阶段 Docker 构建：
1. **构建阶段**: Maven 编译打包
2. **运行阶段**: 精简的 OpenJDK 运行时

优势：
- 镜像体积小
- 构建缓存优化
- 安全性提升

### 5. Kubernetes 部署

#### 部署特性
- **多副本**: 支持水平扩展
- **资源限制**: CPU/内存限制
- **健康检查**: 存活性和就绪性探针
- **服务发现**: ClusterIP 服务
- **配置管理**: ConfigMap 和 Secret

#### 自动扩容 (HPA)
- **指标**: CPU 使用率
- **阈值**: 50%
- **副本范围**: 2-10 个

### 6. CI/CD 流水线

#### 持续集成 (Jenkinsfile)
1. 代码检出
2. Maven 构建
3. 单元测试
4. Docker 镜像构建
5. 镜像推送
6. Kubernetes 部署
7. 集成测试

#### 持续部署 (Jenkinsfile-CD)
1. 参数化部署
2. 环境选择
3. Redis 部署
4. 应用部署
5. 监控配置
6. 健康检查
7. 负载测试

## 负载测试

### Bash 脚本测试
```bash
# 基础负载测试
./scripts/load-test.sh

# 自定义参数
./scripts/load-test.sh -u http://localhost:8080 -r 100 -c 10 -t 60
```

### Python 高级测试
```bash
# 安装依赖
pip install -r requirements.txt

# 运行测试
python scripts/advanced_load_test.py
```

## 监控与可视化

### Grafana 仪表板

包含以下监控面板：
1. **应用概览**: QPS、响应时间、错误率
2. **JVM 监控**: 内存、GC、线程
3. **系统监控**: CPU、内存、磁盘
4. **限流监控**: 通过/拒绝请求数
5. **业务监控**: 自定义业务指标

导入配置文件: `monitoring/grafana-dashboard.json`

## 部署指南

### 开发环境
1. 启动 Redis (可选)
2. 运行 `./mvnw spring-boot:run`
3. 测试接口

### 生产环境
1. 构建镜像: `docker build -t cloud-native-app:latest .`
2. 推送镜像到仓库
3. 部署到 Kubernetes: `kubectl apply -f k8s/`
4. 配置监控和告警

## 常见问题

### Q: 限流不生效？
A: 检查配置文件中的 `rate.limiter.enabled` 是否为 true

### Q: 监控指标为空？
A: 确认 Prometheus 能够访问 `/actuator/prometheus` 端点

### Q: 容器启动失败？
A: 检查 JVM 内存设置和容器资源限制

## 项目贡献者

- **姓名**: [待填写]
- **学号**: [待填写]
- **分工**: [待填写]

## 许可证

本项目采用 MIT 许可证，详见 LICENSE 文件。

## 联系方式

如有问题或建议，请通过以下方式联系：
- Email: [待填写]
- Issues: [待填写]
# cloud-native-app
