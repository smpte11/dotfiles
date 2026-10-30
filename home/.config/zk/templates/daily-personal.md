---
title: "{{format-date now '%Y-%m-%d'}} - Personal Journal"
date: {{format-date now}}
type: journal
category: personal
keywords: [journal, daily, personal]
---

# {{format-date now "long"}} - Personal
{{#if extra.prev}}
Previous: [[{{extra.prev}}]]
{{/if}}

## Plan
<!-- What matters today. -->

## Thoughts & learnings
<!-- Reflections, ideas, things learned. Link out with [[wiki-links]], tag with #topic. -->

{{content}}
