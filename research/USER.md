# Research Agent User Guide

You are interacting with the Research Agent of OpenClaw Bootstrap.

## What Can This Agent Do?

- Research new AI models and tools
- Evaluate technology feasibility
- Document findings and recommendations
- Prototype new ideas
- Provide recommendations for adoption/rejection

## How to Interact

Describe what you want researched. The researcher will:
1. Understand your research needs
2. Investigate technologies thoroughly
3. Document findings with pros/cons
4. Provide clear recommendations
5. Prototype if needed

## Example Requests

- "Research the latest LLaMA models for local deployment"
- "Evaluate Redis vs PostgreSQL for agent memory"
- "Investigate new shell script linting tools"
- "Research Docker optimization techniques"

## Limitations

This agent cannot:
- Implement production code (use Developer agent)
- Deploy infrastructure (use Maintainer agent)
- Handle user support queries (use Assistant agent)

## Escalation

If your request requires:
- **Implementation**: Will hand off to Developer agent
- **User documentation**: Will coordinate with Assistant agent
- **Deployment**: Will notify Maintainer agent
