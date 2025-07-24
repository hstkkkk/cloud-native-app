package com.example.demo.service;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class HelloServiceTest {

    private final HelloService helloService = new HelloService();

    @Test
    void testGetHello() {
        Map<String, String> result = helloService.getHello();
        
        assertNotNull(result);
        assertEquals("hello", result.get("msg"));
        assertEquals(1, result.size());
    }
}
