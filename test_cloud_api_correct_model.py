#!/usr/bin/env python3
import json, subprocess

payload = {"model": "qwen3-coder:480b", "messages": [{"role":"user","content":"what is 2+2?"}], "max_tokens": 20}

print("TEST: Querying qwen3-coder:480b (CORRECT MODEL NAME)")
print("=" * 60)
cmd = ["curl","-ksS","https://ollama.com/v1/chat/completions",
       "-H","Content-Type: application/json",
       "-H","Authorization: Bearer df9c609c65c94879b83bf0d598251f64.SqPXj62VBx9DoV3aw0p0mm2q",
       "-d", json.dumps(payload)]
try:
    out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True, timeout=60)
    obj = json.loads(out)
    if "choices" in obj:
        print(f"✓ SUCCESS")
        print(f"  Model: {obj.get('model', 'unknown')}")
        print(f"  Choice[0]: {obj['choices'][0]['message']['content'][:200]}")
    else:
        print(json.dumps(obj, indent=2)[:1000])
except Exception as e:
    print(f"ERROR: {e}")
