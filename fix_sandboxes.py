#!/usr/bin/env python3
import json
with open('/home/levan/.nemoclaw/sandboxes.json', 'r') as f:
    data = json.load(f)
data['sandboxes']['my-assistant']['model'] = 'qwen3-coder:480b'
with open('/home/levan/.nemoclaw/sandboxes.json', 'w') as f:
    json.dump(data, f, indent=2)
print("✓ Updated model to qwen3-coder:480b")
