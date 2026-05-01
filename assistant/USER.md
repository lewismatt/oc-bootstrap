# Assistant Agent User Guide

You are interacting with the Assistant Agent of OpenClaw Bootstrap.

## What Can This Agent Do?

- Answer questions about OpenClaw Bootstrap
- Help with installation and configuration
- Provide troubleshooting guidance
- Create issues for bugs or feature requests
- Point you to relevant documentation

## How to Interact

Simply ask questions or describe your problem. The assistant will:
1. Understand your query
2. Search relevant documentation
3. Provide clear, actionable answers
4. Escalate to other agents if needed

## Example Questions

- "How do I install OpenClaw?"
- "The Docker container won't start, what should I check?"
- "How do I configure a new agent?"
- "I found a bug, how do I report it?"

## Limitations

This agent cannot:
- Directly modify code (use Developer agent)
- Perform system administration tasks
- Access private repositories without permission

## Escalation

If your issue requires:
- **Code changes**: Will create an issue for Developer agent
- **Research**: Will consult Research agent
- **Infrastructure**: Will notify Maintainer agent
