#!/usr/bin/env python3
import json, subprocess

# Check available models
print("TEST: Getting available models")
print("=" * 60)
cmd = ["curl","-ksS","https://ollama.com/v1/models",
       "-H","Content-Type: application/json",
       "-H","Authorization: Bearer df9c609c65c94879b83bf0d598251f64.SqPXj62VBx9DoV3aw0p0mm2q"]
try:
    out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True, timeout=30)
    obj = json.loads(out)
    if "data" in obj:
        for model in obj["data"][:10]:  # show first 10
            print(f"- {model.get('id', 'unknown')}")
        print(f"... (total: {len(obj['data'])} models)")
    else:
        print(json.dumps(obj, indent=2)[:1000])
except Exception as e:
    print(f"ERROR: {e}")

# Test with a simple available model
print("\n" + "=" * 60)
print("TEST: Listing model names")
print("=" * 60)
cmd = ["curl","-ksS","https://ollama.com/v1/models",
       "-H","Authorization: Bearer df9c609c65c94879b83bf0d598251f64.SqPXj62VBx9DoV3aw0p0mm2q"]
try:
    out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True, timeout=30)
    obj = json.loads(out)
    print("All available models:")
    if "data" in obj:
        for model in obj["data"]:
            print(f"  {model.get('id', 'unknown')}")
except Exception as e:
    print(f"ERROR: {e}")
