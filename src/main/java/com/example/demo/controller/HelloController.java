package com.example.demo.controller;

import com.example.demo.service.HelloService;
import io.github.bucket4j.Bucket;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class HelloController {

    @Autowired
    private HelloService helloService;

    @Autowired
    private Bucket bucket;

    /**
     * Hello API 接口 - 支持限流
     * 当请求频率超过每秒 100 次时，返回 HTTP 状态码 429
     */
    @GetMapping("/hello")
    public ResponseEntity<Map<String, String>> sayHello() {
        // 尝试消费一个令牌
        if (bucket.tryConsume(1)) {
            // 令牌可用，处理请求
            Map<String, String> response = helloService.getHello();
            return ResponseEntity.ok(response);
        } else {
            // 令牌不足，返回限流错误
            Map<String, String> error = new HashMap<>();
            error.put("error", "Too Many Requests");
            error.put("message", "Rate limit exceeded. Please try again later.");
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(error);
        }
    }

    /**
     * 健康检查接口
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> status = new HashMap<>();
        status.put("status", "UP");
        status.put("service", "cloud-native-app");
        return ResponseEntity.ok(status);
    }
}
