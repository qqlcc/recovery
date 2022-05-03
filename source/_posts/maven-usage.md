---
title: Maven 使用记录
date: 2022-03-26 12:00:00
sitemap: true
categories: 
- 构建工具
tags:
- maven
---
记录了使用[Maven](https://maven.apache.org/index.html)的一些命令

## 常用命令

### 构建打包

``` bash
mvn -U -B clean package
```

参考链接: [package](https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html)

### 构建部署
#### 常规部署
``` bash
mvn -U -B clean deploy
```
#### 指定私服地址
```bash
# 插件小于3.0版本
mvn -B -U clean deploy \
-DaltDeploymentRepository=maven-release::default::http://192.168.110.35:8081/repository/maven-release \
-DaltDeploymentRepository=maven-snapshots::default::http://192.168.110.35:8081/repository/maven-snapshots
```

参考链接: [maven-deploy-plugin](https://maven.apache.org/plugins/maven-deploy-plugin/)

### 获取项目信息

``` bash
mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout
mvn help:evaluate -Dexpression=project.version -q -DforceStdout
```

参考链接: [evaluate-mojo](https://maven.apache.org/plugins/maven-help-plugin/evaluate-mojo.html)

### sonar 扫描

``` bash
mvn -U -B clean package sonar:sonar \
  -Dmaven.test.skip=true \
  -Dsonar.scm.disabled=true \
  -Dsonar.projectName=$SONAR_PROJECT \
  -Dsonar.projectKey=$SONAR_PROJECT \
  -Dsonar.host.url=$SONAR_HOST_URL \
  -Dsonar.login=$SONAR_LOGIN \
  -Dsonar.sources=$SONAR_SOURCES \
  -Dsonar.java.binaries=$SONAR_JAVA_BINARIES \
  -Dsonar.exclusions=$SONAR_EXCLUSIONS \
  -Dsonar.java.covergaePlugin=jacoco \
  -Dsonar.jacoco.reportPaths=target/jacoco.exec
```

参考链接: [sonarscanner-for-maven](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-maven/)

## 常用配置  
### Mirrors  
一般情况下配置文件可放在`${user.home}/.m2/settings.xml`
```xml
<settings>
    ...
    <mirrors>
        <mirror>
            <id>aliyunmaven</id>
            <mirrorOf>central</mirrorOf>
            <name>阿里云公共仓库</name>
            <url>https://maven.aliyun.com/repository/public</url>
        </mirror>
        <mirror>
            <id>local</id>
            <name>Local Mirror Repository</name>
            <url>http://192.168.110.35:8081/repository/maven-public</url>
            <mirrorOf>maven-release</mirrorOf>
        </mirror>
    </mirrors>
    ...
</settings>
```
参考链接: [guide-mirror-settings](https://maven.apache.org/guides/mini/guide-mirror-settings.html)