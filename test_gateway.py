#!/usr/bin/env python3
import json, subprocess, sys

# Test via gateway (localhost)
payload = {"model": "qwen3-coder:480b", "messages": [{"role":"user","content":"2+2"}], "max_tokens": 20}

print("TEST: Gateway on localhost:8080")
print("=" * 60)
cmd = ["curl","-ksS","http://localhost:8080/v1/chat/completions",
       "-H","Content-Type: application/json",
       "-H","Authorization: Bearer ollama",
       "-d", json.dumps(payload)]
try:
    out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True, timeout=30)
    obj = json.loads(out)
    if "choices" in obj:
        print("✓ SUCCESS via gateway!")
        print(f"  Response: {obj['choices'][0]['message']['content']}")
    else:
        print(json.dumps(obj, indent=2)[:500])
except Exception as e:
    print(f"ERROR: {e}")
