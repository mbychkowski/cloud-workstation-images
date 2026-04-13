#!/bin/bash
# Event-driven polling script for Gemini CLI Agents
# This script sequentially runs each agent to process its respective queue of GitHub issues.

echo "==========================================="
echo " Starting Gemini CLI Agent Polling Cycle"
echo "==========================================="

echo "=> Running PM Agent..."
gemini --agent pm "Process your queue: query GitHub for issues with label 'status: needs-pm'"

echo "=> Running TPM Agent..."
gemini --agent tpm "Process your queue: query GitHub for issues with label 'status: needs-tpm'"

echo "=> Running QA Agent..."
gemini --agent qa "Process your queue: query GitHub for issues with label 'status: needs-qa'"

echo "=> Running Engineer Agent..."
gemini --agent engineer "Process your queue: query GitHub for issues with label 'status: needs-engineer'"

echo "==========================================="
echo " Polling Cycle Complete."
echo "==========================================="
