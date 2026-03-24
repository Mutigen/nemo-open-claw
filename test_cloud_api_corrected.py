#!/usr/bin/env python3
import json, subprocess

payload = {"model": "qwen3-coder-480b", "messages": [{"role":"user","content":"2+2"}], "max_tokens": 8}

# Korrigierte URL (ohne das "api." prefix)
print("TEST: Using https://ollama.com/v1/chat/completions (CORRECTED)")
print("=" * 60)
cmd = ["curl","-ksS","https://ollama.com/v1/chat/completions",
       "-H","Content-Type: application/json",
       "-H","Authorization: Bearer df9c609c65c94879b83bf0d598251f64.SqPXj62VBx9DoV3aw0p0mm2q",
       "-d", json.dumps(payload)]
try:
    out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True, timeout=30)
    obj = json.loads(out)
    print(json.dumps(obj, indent=2)[:2000])
except Exception as e:
    print(f"ERROR: {e}")
