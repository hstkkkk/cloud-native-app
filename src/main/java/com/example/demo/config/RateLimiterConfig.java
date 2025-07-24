package com.example.demo.config;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

@Configuration
public class RateLimiterConfig {

    @Bean
    public Bucket bucket() {
        // 限制每秒最多100次请求
        Bandwidth limit = Bandwidth.classic(100, Refill.intervally(100, Duration.ofSeconds(1)));
        return Bucket.builder()
                .addLimit(limit)
                .build();
    }
}
