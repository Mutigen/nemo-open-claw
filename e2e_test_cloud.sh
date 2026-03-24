#!/usr/bin/env bash
curl -ksS https://inference.local/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ollama" \
  -d '{"model":"qwen3-coder:480b","messages":[{"role":"user","content":"Write a simple hello world function in Python"}],"max_tokens":100}'
