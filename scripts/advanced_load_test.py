#!/usr/bin/env python3
"""
Advanced Load Testing Script for Cloud Native App
使用 Python 实现的高级压测工具，支持多种测试场景
"""

import asyncio
import aiohttp
import argparse
import json
import time
import statistics
from datetime import datetime
from typing import List, Dict, Tuple
import matplotlib.pyplot as plt
import pandas as pd

class LoadTester:
    def __init__(self, base_url: str, concurrent_users: int = 20):
        self.base_url = base_url.rstrip('/')
        self.concurrent_users = concurrent_users
        self.hello_endpoint = f"{self.base_url}/api/hello"
        self.health_endpoint = f"{self.base_url}/api/health"
        self.metrics_endpoint = f"{self.base_url}/actuator/prometheus"
        
        # Results storage
        self.results = []
        self.rate_limit_results = []
        
    async def check_health(self) -> bool:
        """检查应用健康状态"""
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(self.health_endpoint) as response:
                    if response.status == 200:
                        data = await response.json()
                        return data.get('status') == 'UP'
            return False
        except Exception as e:
            print(f"Health check failed: {e}")
            return False
    
    async def single_request(self, session: aiohttp.ClientSession, endpoint: str) -> Tuple[int, float, str]:
        """发送单个请求并记录响应时间"""
        start_time = time.time()
        try:
            async with session.get(endpoint) as response:
                response_time = time.time() - start_time
                content = await response.text()
                return response.status, response_time, content
        except Exception as e:
            response_time = time.time() - start_time
            return 0, response_time, str(e)
    
    async def rate_limit_test(self, requests_count: int = 150) -> Dict:
        """测试限流功能"""
        print(f"🔒 Testing rate limiting with {requests_count} rapid requests...")
        
        results = {
            'total_requests': requests_count,
            'success_count': 0,
            'rate_limited_count': 0,
            'error_count': 0,
            'response_times': []
        }
        
        async with aiohttp.ClientSession() as session:
            tasks = []
            for i in range(requests_count):
                task = self.single_request(session, self.hello_endpoint)
                tasks.append(task)
                
                # Add small delay to simulate rapid requests
                if i % 10 == 0:
                    await asyncio.sleep(0.1)
            
            responses = await asyncio.gather(*tasks)
            
            for status, response_time, content in responses:
                results['response_times'].append(response_time)
                
                if status == 200:
                    results['success_count'] += 1
                elif status == 429:
                    results['rate_limited_count'] += 1
                else:
                    results['error_count'] += 1
        
        # Calculate statistics
        results['rate_limit_percentage'] = (results['rate_limited_count'] / requests_count) * 100
        results['avg_response_time'] = statistics.mean(results['response_times'])
        
        return results
    
    async def sustained_load_test(self, duration_seconds: int = 60) -> Dict:
        """持续负载测试"""
        print(f"⚡ Running sustained load test for {duration_seconds} seconds with {self.concurrent_users} concurrent users...")
        
        start_time = time.time()
        end_time = start_time + duration_seconds
        
        results = {
            'total_requests': 0,
            'success_count': 0,
            'error_count': 0,
            'rate_limited_count': 0,
            'response_times': [],
            'timestamps': [],
            'status_codes': []
        }
        
        async def worker():
            async with aiohttp.ClientSession() as session:
                while time.time() < end_time:
                    timestamp = time.time()
                    status, response_time, content = await self.single_request(session, self.hello_endpoint)
                    
                    results['total_requests'] += 1
                    results['response_times'].append(response_time)
                    results['timestamps'].append(timestamp)
                    results['status_codes'].append(status)
                    
                    if status == 200:
                        results['success_count'] += 1
                    elif status == 429:
                        results['rate_limited_count'] += 1
                    else:
                        results['error_count'] += 1
                    
                    # Small delay to prevent overwhelming
                    await asyncio.sleep(0.1)
        
        # Create worker tasks
        tasks = [worker() for _ in range(self.concurrent_users)]
        await asyncio.gather(*tasks)
        
        # Calculate statistics
        if results['response_times']:
            results['avg_response_time'] = statistics.mean(results['response_times'])
            results['min_response_time'] = min(results['response_times'])
            results['max_response_time'] = max(results['response_times'])
            results['p95_response_time'] = statistics.quantiles(results['response_times'], n=20)[18]  # 95th percentile
        
        results['qps'] = results['total_requests'] / duration_seconds
        results['success_rate'] = (results['success_count'] / results['total_requests']) * 100 if results['total_requests'] > 0 else 0
        
        return results
    
    def plot_results(self, results: Dict, save_path: str = "/tmp/load_test_results.png"):
        """生成测试结果图表"""
        try:
            fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
            
            # Response time over time
            timestamps = results.get('timestamps', [])
            response_times = results.get('response_times', [])
            
            if timestamps and response_times:
                # Convert timestamps to relative time
                start_time = min(timestamps)
                relative_times = [(t - start_time) for t in timestamps]
                
                ax1.plot(relative_times, response_times, alpha=0.7, linewidth=0.5)
                ax1.set_title('Response Time Over Time')
                ax1.set_xlabel('Time (seconds)')
                ax1.set_ylabel('Response Time (seconds)')
                ax1.grid(True)
            
            # Status code distribution
            status_codes = results.get('status_codes', [])
            if status_codes:
                status_counts = {}
                for code in status_codes:
                    status_counts[code] = status_counts.get(code, 0) + 1
                
                ax2.pie(status_counts.values(), labels=[f"{k} ({v})" for k, v in status_counts.items()], autopct='%1.1f%%')
                ax2.set_title('HTTP Status Code Distribution')
            
            # Response time histogram
            if response_times:
                ax3.hist(response_times, bins=50, alpha=0.7, edgecolor='black')
                ax3.set_title('Response Time Distribution')
                ax3.set_xlabel('Response Time (seconds)')
                ax3.set_ylabel('Frequency')
                ax3.grid(True)
            
            # QPS over time (if we have enough data points)
            if len(timestamps) > 10:
                # Calculate QPS in 5-second windows
                window_size = 5
                qps_data = []
                time_windows = []
                
                for i in range(0, len(timestamps), int(len(timestamps) / 20)):  # 20 data points
                    window_start = timestamps[i]
                    window_end = window_start + window_size
                    
                    requests_in_window = sum(1 for t in timestamps if window_start <= t < window_end)
                    qps = requests_in_window / window_size
                    
                    qps_data.append(qps)
                    time_windows.append((window_start - start_time) / window_size)
                
                ax4.plot(time_windows, qps_data, marker='o')
                ax4.set_title('Requests Per Second Over Time')
                ax4.set_xlabel('Time Window')
                ax4.set_ylabel('QPS')
                ax4.grid(True)
            
            plt.tight_layout()
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
            print(f"📊 Results chart saved to {save_path}")
            
        except Exception as e:
            print(f"Failed to generate charts: {e}")
    
    def print_summary(self, rate_limit_results: Dict, load_test_results: Dict):
        """打印测试结果摘要"""
        print("\n" + "="*60)
        print("📋 LOAD TEST SUMMARY")
        print("="*60)
        
        print("\n🔒 Rate Limiting Test Results:")
        print(f"   Total Requests: {rate_limit_results['total_requests']}")
        print(f"   Successful (200): {rate_limit_results['success_count']}")
        print(f"   Rate Limited (429): {rate_limit_results['rate_limited_count']}")
        print(f"   Rate Limit Percentage: {rate_limit_results['rate_limit_percentage']:.2f}%")
        print(f"   Average Response Time: {rate_limit_results['avg_response_time']:.3f}s")
        
        print("\n⚡ Sustained Load Test Results:")
        print(f"   Total Requests: {load_test_results['total_requests']}")
        print(f"   Successful Requests: {load_test_results['success_count']}")
        print(f"   Rate Limited Requests: {load_test_results['rate_limited_count']}")
        print(f"   Error Requests: {load_test_results['error_count']}")
        print(f"   Success Rate: {load_test_results['success_rate']:.2f}%")
        print(f"   Average QPS: {load_test_results['qps']:.2f}")
        print(f"   Average Response Time: {load_test_results['avg_response_time']:.3f}s")
        print(f"   Min Response Time: {load_test_results['min_response_time']:.3f}s")
        print(f"   Max Response Time: {load_test_results['max_response_time']:.3f}s")
        print(f"   95th Percentile: {load_test_results['p95_response_time']:.3f}s")
        
        print("\n✅ Test completed successfully!")
        print("💡 Check Grafana dashboard for real-time metrics visualization")

async def main():
    parser = argparse.ArgumentParser(description='Cloud Native App Load Tester')
    parser.add_argument('--url', default='http://localhost:8080', help='Application base URL')
    parser.add_argument('--users', type=int, default=20, help='Number of concurrent users')
    parser.add_argument('--duration', type=int, default=60, help='Test duration in seconds')
    parser.add_argument('--rate-limit-requests', type=int, default=150, help='Number of requests for rate limit test')
    
    args = parser.parse_args()
    
    tester = LoadTester(args.url, args.users)
    
    print("🚀 Starting Advanced Load Test for Cloud Native App")
    print(f"📊 Configuration:")
    print(f"   - App URL: {args.url}")
    print(f"   - Concurrent Users: {args.users}")
    print(f"   - Test Duration: {args.duration}s")
    print(f"   - Rate Limit Test Requests: {args.rate_limit_requests}")
    
    # Check health
    print("\n🏥 Checking application health...")
    if not await tester.check_health():
        print("❌ Application health check failed!")
        return
    print("✅ Application is healthy")
    
    # Run rate limiting test
    rate_limit_results = await tester.rate_limit_test(args.rate_limit_requests)
    
    # Wait a bit before sustained test
    print("\n⏳ Waiting 10 seconds before sustained load test...")
    await asyncio.sleep(10)
    
    # Run sustained load test
    load_test_results = await tester.sustained_load_test(args.duration)
    
    # Generate charts
    tester.plot_results(load_test_results)
    
    # Print summary
    tester.print_summary(rate_limit_results, load_test_results)

if __name__ == "__main__":
    # Install required packages if not available
    try:
        import matplotlib.pyplot as plt
        import pandas as pd
    except ImportError:
        print("Installing required packages...")
        import subprocess
        subprocess.check_call(["pip", "install", "matplotlib", "pandas", "aiohttp"])
        import matplotlib.pyplot as plt
        import pandas as pd
    
    asyncio.run(main())
