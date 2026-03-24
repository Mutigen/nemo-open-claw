#!/usr/bin/env bash
cat <<'EOSOCKET' | openshell sandbox connect my-assistant
# Simple cloud API test
python3 <<'PYEOF'
import json, subprocess
payload = {"model": "qwen3-coder:480b", "messages": [{"role":"user","content":"2+2"}], "max_tokens": 20}
cmd = ["curl","-ksS","https://ollama.com/v1/chat/completions","-H","Content-Type: application/json","-H","Authorization: Bearer df9c609c65c94879b83bf0d598251f64.SqPXj62VBx9DoV3aw0p0mm2q","-d", json.dumps(payload)]
out = subprocess.check_output(cmd, text=True, timeout=30)
obj = json.loads(out)
print("✓ Cloud API works!")
print("Response: " + obj['choices'][0]['message']['content'])
PYEOF
exit
EOSOCKET
