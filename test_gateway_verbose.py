#!/usr/bin/env python3
import json, subprocess, sys

payload = {"model": "qwen3-coder:480b", "messages": [{"role":"user","content":"2+2"}], "max_tokens": 20}

print("TEST: Gateway on localhost:8080 (VERBOSE)")
print("=" * 60)
cmd = ["curl","-v","http://localhost:8080/v1/chat/completions",
       "-H","Content-Type: application/json",
       "-H","Authorization: Bearer ollama",
       "-d", json.dumps(payload)]
try:
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    print("STDOUT:")
    print(result.stdout[-2000:] if len(result.stdout) > 2000 else result.stdout)
    print("\nSTDERR:")
    print(result.stderr[-2000:] if len(result.stderr) > 2000 else result.stderr)
except Exception as e:
    print(f"ERROR: {e}")
