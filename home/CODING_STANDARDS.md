## Design
- Rank long-term maintainability, scalability, quality, simplicity and robustness above development cost.
- Make code self-explanatory instead of commenting it: refactor until a comment is unnecessary. This overrides local convention, even in heavily commented code. Trim verbose comments in blocks you edit.
- Every plan gets an "open questions" list. Give each question a falsification step (e2e or source check) that runs before merge.
- Make side-effecting orchestration _idempotent_: record the intent before each effect, skip effects whose result is already recorded, use a single event reader, and keep a long-running core that outlives one-shot commands.
- Before you add CI or automation, assess what it exposes. Prefer local gates (`mise run test:fresh`) over hosted runners. A `workflow_dispatch` job never runs PR-controlled code with secrets.

## Testing
- Start every investigation with a _red_ E2E test that reproduces the bug the way the end user meets it. Write it even when code, logs or a schema already suggest a cause: a static diagnosis is a hypothesis.
- Fix every lint error, failing test and flaky test you see, yours or not. Ask for help with a failing test you cannot fix.
- Run the narrowest authoritative test locally before you report done. If the environment cannot run it (no docker, no network), mark verification as pending in the PR. Name the gate that actually ran; "CI covers it" is banned when CI was removed or is not the gate.

## Shipping
- Ship small verified batches: merge a change with the follow-ups it already needs, or live-verify on the target machine in the same session.
- Write commit messages as conventional commits in the imperative mood: "feat: add new feature".
- Credit agents only as co-reviewers on PRs and commits authored from my work account, never as co-author.
- End every PR body with a short retrospective: what the plan got wrong and the rule it implies.
