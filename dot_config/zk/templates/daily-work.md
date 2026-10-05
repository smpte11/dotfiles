---
title: "{{format-date now '%Y-%m-%d'}} - Work Journal"
date: {{format-date now}}
type: journal
category: work
keywords: [journal, daily, work]
---

# {{format-date now "long"}} - Work
{{#if extra.prev}}
Previous: [[{{extra.prev}}]]
{{/if}}

## Morning routine
- [ ] Catch up on Slack: mentions, DMs, team channels
- [ ] Check metrics & dashboards for anomalies
- [ ] Triage inbox & review notifications (PRs, reviews, issues)
- [ ] Scan calendar for today's meetings
- [ ] Set top 1-3 priorities below

## Plan
<!-- What matters today. -->

## Thoughts & learnings
<!-- Reflections, ideas, things learned. Link out with [[wiki-links]], tag with #topic. -->

{{content}}
