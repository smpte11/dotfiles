# Felix's Agents Instructions

## General
- Avoid writing `.md` files and other unnecessary artifacts. This covers READMEs for new or scaffolded projects and scratch files used to stage text for another tool; write one only when the user asks for it.
- If a task or an E2E test needs an artifact that the repository does not need, clean it up afterwards.
- If `~/.agents/machine/` exists, read every file in it before doing anything else; each machine keeps its own rules there.
- Respect the machine pin (`/etc/machine-id`) and treat mounts you do not know as read-only; ask before any write outside the work directory.
- Verify facts against the live source before stating them: image tags against the registry, config paths against the deployed file on the machine, secret names against the vault entry, port behavior against the container runtime. If you cannot verify in the sandbox, write "unverified" and name the check that would falsify it.

## Writing
- Never use em dashes "—" in anything you write: chat responses, explanations, code, commit messages, PR bodies. Use hyphens "-" instead. This holds for every task type; a coding, review or debugging task does not exempt your own prose.
- Avoid emojis in your responses.
- When you explain something to me (answers, summaries, explanations of files or code), follow `~/.agents/output-styles/ste-80.md`.
- When you draft or edit text for publication (articles, posts, introductions), do not use STE. Read and follow `~/VOICE.md`.
- When asked to write "in my voice" (PR bodies, review comments, tickets, messages), read and follow `~/VOICE.md`.

## Version Control System (VCS)
- Use Jujutsu for version control, including read-only inspection: reach for `jj st`, `jj diff`, `jj log`, `jj git clone` rather than their `git` equivalents. Fall back to Git only for what Jujutsu cannot do.

## Engineering
- Before you write or change code, debug, run tests or lint, plan, add CI or automation, build orchestration, commit, or open a PR, read `~/CODING_STANDARDS.md`, my engineering standards.
