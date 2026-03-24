#!/usr/bin/env python3
import json, subprocess

payload = {"model": "qwen3-coder-480b", "messages": [{"role":"user","content":"2+2"}], "max_tokens": 8}

# Test 1: mit Bearer header, mit full response
print("TEST 1: Authorization: Bearer <key>")
print("=" * 60)
cmd = ["curl","-v","https://api.ollama.com/v1/chat/completions",
       "-H","Content-Type: application/json",
       "-H","Authorization: Bearer df9c609c65c94879b83bf0d598251f64.SqPXj62VBx9DoV3aw0p0mm2q",
       "-d", json.dumps(payload)]
try:
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    print("STDOUT:", out.stdout[-1000:] if len(out.stdout) > 1000 else out.stdout)
    print("\nSTDERR:", out.stderr[-500:] if len(out.stderr) > 500 else out.stderr)
except Exception as e:
    print(f"ERROR: {e}")
