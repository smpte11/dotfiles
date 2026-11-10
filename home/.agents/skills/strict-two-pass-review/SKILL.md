---
name: strict-two-pass-review
description: "Run two sequential review passes over findings, reports, or plans: first a standard pass that re-verifies every claim against primary sources, then a strict adversarial pass that attacks biases and reclassifies weak claims. Use when a review must get stricter in stages, or to check whether previous findings hold."
---

# Strict two-pass review

Use this when asked to review findings, reports, plans, or your own previous output, especially when the review must get stricter in stages. Run the passes one after the other, not in parallel.

## Pass 1: standard review

- Re-verify every claim against primary sources: commits, files, issue and PR bodies. Never verify a claim against your own summary or memory.
- Correct or downgrade any claim that does not check out. Record the evidence you used: commit hash, file path, issue number.
- Recompute the statistics you quote from the raw data, and state the time window or sample you used.

## Pass 2: strict adversarial review

Attack each claim that survived pass 1:

- Name the biases in your own evidence: self-authored sources, selection bias, base rates, correlation versus causation, category errors.
- For each claim, state what evidence would falsify it, and check whether that evidence is available.
- Reclassify anything that does not survive: downgrade the severity, or reframe it. A design backlog is not an incident; a no-op revert is not an exposure that shipped.
- Disclose that both passes ran in the same model. The result is a self-review, not an independent second opinion.

## Output

- A verdict table: each finding marked holds, downgraded, or reclassified, with the evidence for each.
- A short list of what changed between pass 1 and pass 2.

## Writing rules for the output

- Do not use em dashes. Use hyphens.
- No emojis.
- One idea per sentence, short sentences, active voice.

## Notes

- In Mistral Studio / Vibe the same skill lives in the workspace skill registry under the name `strict-two-pass-review`; keep the two in sync when you edit one.
- This file follows the agentskills.io layout (`~/.agents/skills/<name>/SKILL.md`), so harnesses that read that directory pick it up on every machine bootstrapped from this repo.
