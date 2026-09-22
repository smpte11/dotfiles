# Felix's Agents Instructions

The followings are the instructions for using Felix's agents. Please read them carefully before proceeding. Theses apply in all scenarios.

## General Instructions and Guidelines

## General
- Avoid writing `.md` files and other unnecessary artifacts. This covers READMEs for new or scaffolded projects and scratch files used to stage text for another tool; write one only when the user asks for it.
- Do not leave unnecessary artifacts in the repository.
If an artifact is required, for example as an output of a task or an E2E test, yet not necessary, cleanup afterwards.

### Writing
- Never use em dashes "—" in anything you write: chat responses, explanations, code, commit messages, PR bodies. Use hyphens "-" instead. This holds for every task type; a coding, review or debugging task does not exempt your own prose.
- Avoid emojis in your responses.
- Favour terseness over unnecessary verbosity. Avoid long-winded explanations and unnecessary details.

### Version Control System (VCS)
- Use Jujutsu for version control, including read-only inspection: reach for `jj st`, `jj diff`, `jj log`, `jj git clone` rather than their `git` equivalents. Fall back to Git only for what Jujutsu cannot do.
- When writing commit messages, use conventional commit format. For example, "feat: add new feature" or "fix: correct typo in code".
- When writing commit messages, use the imperative mood. For example, "Add new feature" instead of "Added new feature".
- When writing commit messages, never add yourself as a co-author. However, agents may be added as co-reviewers in PRs and commits when the commit author is kivra-felbro.

### Engineering
- Avoid comments in code. If you find a comment to be necessary, it is likely that the code is not clear enough and should be refactored.
This applies even when surrounding code already has comments. Do not add or extend comments to match local style; the rule overrides existing convention. When editing a block that has verbose comments, prefer trimming them.
- Do not give too much weight to development cost when making technical decisions.
Focus on the long-term maintainability, scalability, quality, simplicity and robustness of the codebase.
- When investigating or debugging an issue, always start with reproducing the bug in an E2E test that is as closely align with how the end user would use the feature as possible.
This will help you find the actual problem and fix it.
Do this even when reading the code, the logs or a schema already suggests a cause; a static diagnosis is a hypothesis, not a reproduction.
- Always apply the same high standards for engineering excellence: lint, test failures and flakiness.
If you see even one of those, fix it. Regardless of whether it is your code or not.
If you see a flaky test, fix it.
If you see a lint error, fix it.
If you see a failing test, fix it. If you see a failing test that is not your code, fix it.
If you see a failing test that is not your code and you don't know how to fix it, ask for help.


