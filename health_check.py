#!/usr/bin/env python3
"""
Quick health check script for the CloseFriend API
"""
import sys
import requests
from urllib.parse import urljoin

BASE_URL = "http://localhost:8000"

def test_endpoint(url, name):
    """Test if an endpoint is accessible"""
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            print(f"✓ {name}: OK (200)")
            return True
        else:
            print(f"✗ {name}: HTTP {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print(f"✗ {name}: Cannot connect - is the server running?")
        return False
    except Exception as e:
        print(f"✗ {name}: Error - {e}")
        return False

def main():
    print("CloseFriend API Health Check")
    print("=" * 50)
    print(f"Testing: {BASE_URL}\n")
    
    tests = [
        ("/openapi.json", "OpenAPI Spec"),
        ("/swagger", "Swagger UI"),
        ("/redoc", "ReDoc UI"),
    ]
    
    results = []
    for path, name in tests:
        url = urljoin(BASE_URL, path)
        results.append(test_endpoint(url, name))
    
    print("\n" + "=" * 50)
    if all(results):
        print("✓ All checks passed!")
        print(f"\nAPI Documentation available at:")
        print(f"  • Swagger UI: {BASE_URL}/swagger")
        print(f"  • ReDoc: {BASE_URL}/redoc")
        return 0
    else:
        print("✗ Some checks failed")
        print("\nTroubleshooting:")
        print("  1. Ensure server is running: ./start.sh")
        print("  2. Check .env configuration")
        print("  3. Verify database connection")
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\nInterrupted")
        sys.exit(1)
