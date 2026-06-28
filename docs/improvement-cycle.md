# Improvement Cycle Workflow

> **How to run:** Paste the instruction block below into Codebuff at the start of a session to trigger a continuous improvement sprint.

## Instruction

```
I want you to work on every part of this app, from codebase to performance to UI to UX to front end to back end to product management, EVERYTHING. I want you to follow this simple cycle: Identify an issue in one or more of these factors, decide on the best course of action to fix it, fix it, and make sure it works, then repeat. Do not do this until you think you are done, do not do this until you want to be done. Only finish this when I press escape, making you cancel your current task. I will then give you further instructions. I want to make sure this is absolutely clear to you, so you dont finish working early and you dont have to turn to me for guidance every change you want to make. I give you full permissions. When doing this, go in depth, research good practices, understand what real apps do so you can implement it here: do not guess. I will submit this prompt to you, and I want you to read it, then simply give me a one word confirmation "UNDERSTOOD" to confirm that you understand these instructions and will not hesitate to complete it to the letter. After typing "UNDERSTOOD", do not wait for further instructions, just go on with the cycle.
```

## What the cycle looks like

| Step | Description |
|------|-------------|
| **Identify** | Audit code, UI, UX, performance, accessibility, or product gaps — read files, search for patterns, compare against real-world app practices. |
| **Decide** | Choose the highest-impact fix. If unsure between options, use `thinker-with-files-gemini` to reason through trade-offs. |
| **Fix** | Implement the change. Follow project conventions, reuse existing helpers, keep diffs minimal. |
| **Validate** | Run `dart analyze` + `flutter test` in parallel. For non-trivial changes, also spawn `code-reviewer-deepseek`. |
| **Repeat** | Move to the next issue immediately — don't pause, don't summarize, don't wait for permission. |

## Guidelines learned from previous sprints

- **Batch small changes** — do multiple independent edits in one turn, validate all at once.
- **Fix reviewer feedback same-turn** — if `code-reviewer-deepseek` flags issues, fix them before moving to the next cycle.
- **Deploy periodically** — every ~10 improvements, commit + push so CI picks it up and the web app updates.
- **Update tests inline** — when changing widget types (e.g. spinner → shimmer), update the test finders immediately so `flutter test` stays green.
- **Scrape hard** — if the next cycle turns out already implemented, pivot instantly. Don't spend more than one turn investigating.
- **End only on escape** — the instruction says the user will press escape to stop. Don't self-terminate.

## Example improvements from a real sprint

- Tournament doubles partners → empty instead of fake "Player A Partner" names
- Production error boundary with crash recovery UI
- Home screen performance: extracted `_MatchHistorySection` to isolate search rebuilds
- Shimmer loading skeletons replacing all `CircularProgressIndicator` instances
- 300ms search debounce
- Adaptive 600px max-width layout for web/tablet
- Pull-to-refresh on tournament bracket
- `keyboardDismissBehavior: onDrag` added to all scroll views
- Match card type icons (person/people) with accessibility labels
- Tournament refresh flicker fix (skip shimmer during pull-to-refresh)
