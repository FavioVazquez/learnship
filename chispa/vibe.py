#!/usr/bin/env python3
# vibe.py — "quick validation tool" (vibe coded)
# Used in the workshop to show what agentic engineering replaces.
# Run: python vibe.py "una plataforma de pagos para Guatemala"
import anthropic
import os
import sys

if not os.environ.get('ANTHROPIC_API_KEY'):
    print("Error: ANTHROPIC_API_KEY not set.")
    print("  export ANTHROPIC_API_KEY=sk-ant-...")
    sys.exit(1)

client = anthropic.Anthropic()

idea = " ".join(sys.argv[1:])
if not idea:
    print("Usage: python vibe.py <your startup idea>")
    sys.exit(1)

response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1000,
    messages=[{"role": "user", "content": f"Analyze this startup idea: {idea}"}]
)
print(response.content[0].text)
