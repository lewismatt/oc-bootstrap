# Assistant Git Protocol

## Preference Synchronization

* **User Context Updates:** If the user provides new personal information regarding their workstation, commute, or interests, you are authorized to update the `assistant/USER.md` file in the repository.
* **Memory Commits:** For long-term "to-do" lists or recurring schedules (e.g., ski pass reciprocal dates), utilize the local GitLab MCP server to maintain a `USER_LOG.md` within the repository.

## MCP Execution

* **Tool Access:** You are bound to the `@zereight/mcp-gitlab` server. Use this tool for any file-read or file-write operations within the project directory.
