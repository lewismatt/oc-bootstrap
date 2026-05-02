# User Context - Research Agent

This file helps the Research Agent tailor its investigations to your specific interests, industries, and information needs.

## Research Interests

### Technology Topics

- [ ] **AI/Machine Learning:** Local LLM deployment, open-source models, GPU optimization
- [ ] **Software Development:** Python automation, bash scripting, GitOps workflows
- [ ] **Infrastructure:** Self-hosted services, privacy-focused tools, local-first software
- [ ] [Add your technology interests]

### Industry Focus

- [ ] Open-source software trends
- [ ] AI regulation and policy developments
- [ ] Privacy and data security news
- [ ] [Add your industry focus areas]

### Personal Interests

- [ ] [Add your hobbies, sports teams, music artists, etc.]
- Example: "Colorado Avalanche hockey, Tyler Childers tour dates, ski conditions"

## Research Preferences

**Source Priorities:**

1. Official documentation and technical blogs
2. Peer-reviewed research and academic papers
3. Established tech news outlets (Ars Technica, The Verge, Hacker News)
4. GitHub repositories and release notes
5. Reddit technical communities (r/LocalLLaMA, r/selfhosted)

**Avoid:**

- Clickbait or sensationalist sources
- Content farms and SEO spam
- Unverified social media rumors (unless explicitly researching sentiment)

**Citation Style:**

- Always include URLs for verification
- Prefer primary sources over aggregators
- Note publication dates for time-sensitive topics
- Distinguish between facts, analysis, and speculation

## Ongoing Monitoring Topics

**Active Alerts:** (Topics you want regular updates on)

1. **[Topic 1]:**
   - [ ] New releases and changelogs
   - [ ] Community discussions and issues
   - [ ] Integration guides and tutorials

2. **[Topic 2]:**
   - [ ] [Add specific aspects to monitor]
   - [ ] [Add more aspects]

3. **[Add your own topics]:**
   - Example: "Linux kernel security updates"
   - Example: "Raspberry Pi new product announcements"

## Research Output Preferences

**Format:**

- Start with executive summary (2-3 sentences)
- Use bullet points for key findings
- Include full analysis for complex topics
- Always provide source links

**Depth Levels:**

- **Quick Answer:** 1-2 paragraphs with sources (for simple factual queries)
- **Standard Research:** 3-5 key findings with analysis (default)
- **Deep Dive:** Comprehensive report with cross-referencing (when requested)

**Archival:**

- If Git integration is configured, commit important research to `research/logs/`
- Use descriptive filenames: `YYYY-MM-DD-topic-slug.md`
- Tag research by category in commit messages

## Example Research Requests

**Quick Factual:**

> "What's the current stable version of Python?"

> Expected: Brief answer with link to Python.org release page

**Standard Investigation:**

> "What are the best practices for securing a self-hosted web server?"

> Expected: 5-7 recommendations with sources, security audit checklist, links to hardening guides

**Deep Research:**

> "Research the pros and cons of different vector databases for local AI memory systems."

> Expected: Comparison table, performance benchmarks, integration complexity analysis, recommendation based on your constraints, full report committed to research/logs/

## Sentiment Analysis Guidelines

When analyzing social media or community sentiment:

**Sample Size:** Aim for 1000+ mentions for statistical relevance

**Time Window:** Default to 24-48 hours for trending topics

**Breakdowns to Include:**

- Overall sentiment distribution (positive/neutral/negative %)
- Top themes in each category
- Demographic insights (if available)
- Trend direction (sentiment improving/declining)

**Caveats to Note:**

- Bot activity and astroturfing
- Echo chamber effects
- Selection bias in platform choice

## Fact-Checking Protocol

**For Claims to Verify:**

1. Search for primary sources (official statements, research papers)
2. Cross-reference with 3+ independent credible sources
3. Check publication dates (is information current?)
4. Note any conflicts or uncertainty
5. Provide verdict: Verified / Likely True / Unconfirmed / False

**Red Flags:**

- "According to sources..." without attribution
- Extraordinary claims without extraordinary evidence
- Information that conflicts with established facts
- Very recent claims without credible coverage

## Time Zones & Scheduling

**Primary Time Zone:** [Your Time Zone - e.g., Mountain Time (MT)]

**Best Times for Real-Time Research:**

- Breaking news: Monitor between [time range]
- Stock/crypto updates: Market hours + after-hours
- Social trends: Peak activity [time range]

---

*Note: The Research Agent can update this file as it learns your interests and preferences. You can also edit manually: `nano ~/.openclaw/workspace-research/USER.md`*
