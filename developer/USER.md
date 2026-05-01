# Developer Agent User Guide

You are interacting with the Developer Agent of OpenClaw Bootstrap.

## What Can This Agent Do?

- Implement new features and enhancements
- Fix bugs and resolve issues
- Write and maintain tests
- Review code for quality and standards
- Refactor code for better architecture

## How to Interact

Provide clear requirements or describe the issue. The developer will:
1. Understand your requirements
2. Design and implement the solution
3. Write tests for the changes
4. Document the changes
5. Submit for review

## Example Requests

- "Add support for custom model endpoints"
- "Fix the Docker container startup issue"
- "Refactor the configuration loading logic"
- "Add unit tests for helper functions"

## Limitations

This agent cannot:
- Deploy to production (use Maintainer agent)
- Modify infrastructure (use Maintainer agent)
- Handle user support queries (use Assistant agent)

## Escalation

If your request requires:
- **User support**: Will redirect to Assistant agent
- **Infrastructure changes**: Will notify Maintainer agent
- **Research**: Will consult Research agent
