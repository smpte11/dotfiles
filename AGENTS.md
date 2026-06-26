# Felix's Agents Instructions

The followings are the instructions for using Felix's agents. Please read them carefully before proceeding. Theses apply in all scenarios.

## General Instructions and Guidelines

### Writing
- Never use em dashes "—" in your responses. Use hyphens "-" instead.
- Avoid writing `.md` files and other unnecessary artifacts.

### Version Control System (VCS)
- Use Jujutsu for version control. You may have to use Git for some tasks, but Jujutsu is preferred.
- When writing commit messages, use conventional commit format. For example, "feat: add new feature" or "fix: correct typo in code".
- When writing commit messages, use the imperative mood. For example, "Add new feature" instead of "Added new feature".
- When writing commit messages, never add yourself as a co-author.

### Engineering
- Do not give too much weight to development cost when making technical decisions.
Focus on the long-term maintainability, scalability, quality, simplicity and robustness of the codebase.
- When investigating or debugging an issue, always start with reproducing the bug in an E2E test that is as closely align with how the end user would use the feature as possible.
This will help you find the actual problem and fix it.
- Always apply the same high standards for engineering excellence: lint, test failures and flakiness.
If you see even one of those, fix it. Regardless of whether it is your code or not.
If you see a flaky test, fix it.
If you see a lint error, fix it.
If you see a failing test, fix it. If you see a failing test that is not your code, fix it.
If you see a failing test that is not your code and you don't know how to fix it, ask for help.


