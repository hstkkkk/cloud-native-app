# 📚 云原生应用文档索引

本目录包含云原生应用项目的完整文档，帮助您理解、部署和运维整个系统。

## 📖 文档结构

### 核心文档
| 文档 | 描述 | 适用对象 |
|------|------|----------|
| [README.md](../README.md) | 项目概述和快速开始指南 | 所有用户 |
| [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) | 详细部署指南和故障排查 | 开发者/运维 |
| [PROJECT_REPORT.md](./PROJECT_REPORT.md) | 完整项目报告和技术文档 | 项目评审 |

### 配置文件
| 文件 | 用途 | 位置 |
|------|------|------|
| `pom.xml` | Maven 构建配置 | 根目录 |
| `application.yml` | 应用配置 | src/main/resources/ |
| `Dockerfile` | 容器构建配置 | 根目录 |
| `Jenkinsfile` | CI 流水线配置 | 根目录 |
| `Jenkinsfile-CD` | CD 流水线配置 | jenkins/ |

### Kubernetes 部署
| 文件 | 功能 | 位置 |
|------|------|------|
| `deployment.yaml` | 应用部署配置 | k8s/ |
| `servicemonitor.yaml` | 监控配置 | k8s/ |
| `hpa.yaml` | 自动扩容配置 | k8s/ |
| `redis.yaml` | Redis 部署配置 | k8s/ |

### 监控配置
| 文件 | 功能 | 位置 |
|------|------|------|
| `grafana-dashboard.json` | Grafana 仪表板 | monitoring/ |

### 自动化脚本
| 脚本 | 功能 | 位置 |
|------|------|------|
| `setup.sh` | 环境设置和项目部署 | scripts/ |
| `validate-project.sh` | 项目验证和测试 | scripts/ |
| `load-test.sh` | 基础负载测试 | scripts/ |
| `advanced_load_test.py` | 高级性能测试 | scripts/ |

## 🚀 快速开始路径

### 1. 新用户入门
```bash
# 阅读项目概述
cat README.md

# 验证环境和项目
./scripts/validate-project.sh

# 一键设置环境
./scripts/setup.sh --all
```

### 2. 开发者快速上手
```bash
# 1. 克隆项目
git clone <repository-url>
cd cloud-native-app

# 2. 构建和测试
./mvnw clean package
./mvnw test

# 3. 本地运行
./mvnw spring-boot:run

# 4. 测试接口
curl http://localhost:8080/api/hello
```

### 3. 部署到生产环境
```bash
# 1. 构建镜像
docker build -t cloud-native-app:latest .

# 2. 部署到 Kubernetes
kubectl apply -f k8s/

# 3. 验证部署
kubectl get pods -n cloud-native
```

## 📋 文档使用指南

### 按角色分类

#### 🔧 开发者
**推荐阅读顺序:**
1. [README.md](../README.md) - 了解项目概述
2. [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - 本地开发环境搭建
3. 源码结构分析
4. 单元测试编写

**关键文件:**
- `src/main/java/` - 应用源码
- `src/test/java/` - 单元测试
- `application.yml` - 应用配置
- `pom.xml` - 依赖管理

#### 🚀 运维工程师
**推荐阅读顺序:**
1. [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - 完整部署指南
2. Kubernetes 配置文件分析
3. 监控系统配置
4. 故障排查流程

**关键文件:**
- `k8s/` - Kubernetes 部署配置
- `monitoring/` - 监控配置
- `Dockerfile` - 容器构建
- Jenkins 流水线配置

#### 📊 项目经理/技术负责人
**推荐阅读顺序:**
1. [README.md](../README.md) - 项目概述
2. [PROJECT_REPORT.md](./PROJECT_REPORT.md) - 完整技术报告
3. 系统架构分析
4. 技术选型说明

**关键内容:**
- 技术架构图
- 项目进度和里程碑
- 技术风险和解决方案
- 性能测试结果

#### 🎓 学习者
**推荐学习路径:**
1. [README.md](../README.md) - 理解云原生概念
2. [PROJECT_REPORT.md](./PROJECT_REPORT.md) - 学习技术实现
3. [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - 动手实践
4. 源码阅读和实验

## 🛠️ 常用操作参考

### 本地开发
```bash
# 启动应用
./mvnw spring-boot:run

# 运行测试
./mvnw test

# 打包应用
./mvnw package

# 运行 JAR
java -jar target/cloud-native-app-1.0.0.jar
```

### 容器操作
```bash
# 构建镜像
docker build -t cloud-native-app:latest .

# 运行容器
docker run -p 8080:8080 cloud-native-app:latest

# 查看日志
docker logs <container-id>

# 进入容器
docker exec -it <container-id> /bin/bash
```

### Kubernetes 操作
```bash
# 部署应用
kubectl apply -f k8s/

# 查看状态
kubectl get pods,svc,hpa -n cloud-native

# 查看日志
kubectl logs -f deployment/cloud-native-app -n cloud-native

# 端口转发
kubectl port-forward svc/cloud-native-app 8080:8080 -n cloud-native

# 扩容/缩容
kubectl scale deployment cloud-native-app --replicas=3 -n cloud-native
```

### 监控和调试
```bash
# 查看指标
curl http://localhost:8080/actuator/prometheus

# 健康检查
curl http://localhost:8080/api/health

# 应用信息
curl http://localhost:8080/actuator/info

# 查看配置
curl http://localhost:8080/actuator/configprops
```

### 测试和验证
```bash
# 项目验证
./scripts/validate-project.sh

# 负载测试
./scripts/load-test.sh

# 高级测试
python scripts/advanced_load_test.py
```

## 🔍 故障排查快速参考

### 常见问题
| 问题 | 可能原因 | 解决方案 | 参考文档 |
|------|----------|----------|----------|
| 应用启动失败 | Java 版本、端口占用 | 检查环境、更换端口 | [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md#故障排查指南) |
| 容器构建失败 | Dockerfile 错误、网络问题 | 检查语法、使用镜像 | [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md#容器问题) |
| Pod 无法调度 | 资源不足、标签错误 | 调整资源、检查配置 | [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md#kubernetes-问题) |
| 监控无数据 | 配置错误、网络不通 | 检查配置、测试连通性 | [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md#监控问题) |

### 日志位置
| 组件 | 日志位置 | 查看命令 |
|------|----------|----------|
| 应用日志 | stdout | `kubectl logs -f deployment/cloud-native-app` |
| 容器日志 | Docker | `docker logs <container-id>` |
| 系统日志 | journald | `journalctl -u <service>` |
| Jenkins 日志 | Web UI | 访问构建历史 |

## 📚 扩展阅读

### 技术文档
- [Spring Boot 官方文档](https://spring.io/projects/spring-boot)
- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [Docker 官方文档](https://docs.docker.com/)
- [Prometheus 文档](https://prometheus.io/docs/)

### 最佳实践
- [12-Factor App](https://12factor.net/)
- [云原生应用架构指南](https://github.com/cncf/landscape)
- [Kubernetes 最佳实践](https://kubernetes.io/docs/concepts/configuration/overview/)

### 相关项目
- [Spring Cloud](https://spring.io/projects/spring-cloud)
- [Istio Service Mesh](https://istio.io/)
- [ArgoCD GitOps](https://argo-cd.readthedocs.io/)

## 📞 支持和反馈

### 获取帮助
1. **查看文档**: 首先查看相关文档和故障排查指南
2. **运行验证**: 使用 `./scripts/validate-project.sh` 诊断问题
3. **查看日志**: 检查应用和系统日志
4. **社区支持**: 在相关技术社区寻求帮助

### 贡献指南
1. **报告问题**: 通过 Issue 报告 Bug 或建议
2. **提交改进**: 通过 Pull Request 贡献代码
3. **完善文档**: 帮助改进和更新文档
4. **分享经验**: 分享使用经验和最佳实践

### 版本历史
| 版本 | 日期 | 主要变更 |
|------|------|----------|
| v1.0.0 | [日期] | 初始版本，基础功能完成 |
| v1.1.0 | [日期] | 增加监控和自动扩容 |
| v1.2.0 | [日期] | 完善 CI/CD 流水线 |

---

📝 **文档维护**: 本文档将持续更新，确保与项目代码同步。如发现文档过期或错误，请及时反馈。

💡 **使用建议**: 建议先阅读 README.md 了解项目概况，再根据具体需求选择相应的详细文档。

🎯 **学习目标**: 通过本项目实践，掌握云原生应用开发的完整流程和关键技术。
