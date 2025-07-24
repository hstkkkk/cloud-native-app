package com.example.demo.service;

import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class HelloService {
    public Map<String, String> getHello() {
        return Map.of("msg", "hello");
    }
}
