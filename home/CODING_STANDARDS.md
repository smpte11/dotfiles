# Coding Standards

## Code
- Avoid comments in code. If a comment seems necessary, refactor the code until it is clear without one. This rule overrides local convention: do not add or extend comments to match surrounding code. When editing a block that has verbose comments, prefer trimming them.
- Do not give too much weight to development cost when making technical decisions. Focus on the long-term maintainability, scalability, quality, simplicity and robustness of the codebase.

## Debugging
- When investigating or debugging an issue, always start by reproducing the bug in an E2E test that is as closely aligned with how the end user would use the feature as possible. Do this even when reading the code, the logs or a schema already suggests a cause; a static diagnosis is a hypothesis, not a reproduction.

## Tests and Lint
- Fix every lint error, failing test and flaky test you see, whether or not it is your code. If you cannot fix a failing test, ask for help.
- Run the narrowest authoritative test locally before reporting done. If the environment cannot run it (no docker, no network), mark verification as pending in the PR. Never write "CI covers it" when CI was removed or is not the gate.

## Planning
- Every plan gets an "open questions" list. Each item gets a falsification step (e2e or source check) that runs before merge, not after.
- Prefer small verified batches: merge a change together with the follow-ups it already needs, or live-verify on the target machine in the same session.

## CI and Automation
- Before adding any CI or automation, assess what it exposes: no `workflow_dispatch` job may run PR-controlled code with secrets. Prefer local gates (`mise run test:fresh`) over hosted runners.

## Orchestration
- Any side-effecting orchestration you build must be idempotent: record the intent before running the effect, skip effects whose result is already recorded, use a single event reader, and keep a long-running core that outlives one-shot commands.

## Commits and PRs
- Write commit messages in conventional commit format and the imperative mood, for example "feat: add new feature", not "feat: added new feature". Never add yourself as a co-author; agents may be added as co-reviewers in PRs and commits only when the commit is authored from my work account.
- End every PR body with a short retrospective: what the plan got wrong and the rule it implies.
