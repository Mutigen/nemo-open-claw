#!/usr/bin/env python3
import json, subprocess, sys

payload = {"model": "qwen3-coder-480b", "messages": [{"role":"user","content":"2+2"}], "max_tokens": 8}

# Test 1: mit Bearer header
print("=" * 60)
print("TEST 1: Authorization: Bearer <key>")
print("=" * 60)
cmd = ["curl","-ksS","https://api.ollama.com/v1/chat/completions",
       "-H","Content-Type: application/json",
       "-H","Authorization: Bearer df9c609c65c94879b83bf0d598251f64.SqPXj62VBx9DoV3aw0p0mm2q",
       "-d", json.dumps(payload)]
try:
    out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True, timeout=30)
    obj = json.loads(out)
    print(json.dumps(obj, indent=2)[:1000])
except Exception as e:
    print(f"ERROR: {e}")

# Test 2: nur API key ohne Bearer
print("\n" + "=" * 60)
print("TEST 2: Authorization: <key>")
print("=" * 60)
cmd = ["curl","-ksS","https://api.ollama.com/v1/chat/completions",
       "-H","Content-Type: application/json",
       "-H","Authorization: df9c609c65c94879b83bf0d598251f64.SqPXj62VBx9DoV3aw0p0mm2q",
       "-d", json.dumps(payload)]
try:
    out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True, timeout=30)
    obj = json.loads(out)
    print(json.dumps(obj, indent=2)[:1000])
except Exception as e:
    print(f"ERROR: {e}")

# Test 3: x-api-key header
print("\n" + "=" * 60)
print("TEST 3: x-api-key: <key>")
print("=" * 60)
cmd = ["curl","-ksS","https://api.ollama.com/v1/chat/completions",
       "-H","Content-Type: application/json",
       "-H","x-api-key: df9c609c65c94879b83bf0d598251f64.SqPXj62VBx9DoV3aw0p0mm2q",
       "-d", json.dumps(payload)]
try:
    out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True, timeout=30)
    obj = json.loads(out)
    print(json.dumps(obj, indent=2)[:1000])
except Exception as e:
    print(f"ERROR: {e}")
