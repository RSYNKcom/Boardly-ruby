# 02 · Nudge owners about stale cards

**Feature:** Stale-card nudges · **Who it's for:** teams where cards silently rot in a column.

## The problem

A ticket has been "In Review" for a week. Nobody notices because nothing prompts them. Work-in-progress piles up and cycle time creeps.

## The setup

```yaml
fields:
  status: Status
features:
  staleNudge:
    enabled: true
    rules:
      - status: "In Progress"
        days: 3
        notify: assignees
        message: "Heads up — this has been **In Progress** for {days} days. Any blockers?"
      - status: "In Review"
        days: 2
        notify: ["team-lead", "qa-bot"]   # explicit logins instead of assignees
      - status: "Blocked"
        days: 1
        notify: ["assignees", "project-manager"]   # assignees *and* an extra person
```

Only statuses that have a rule are watched — a card in a status you didn't list is never nudged. That makes "In Progress" nudges opt-in: drop the rule to stop them, add one to turn them on.

The `notify` target can be:

- `assignees` — @-mention whoever is assigned to the card.
- a list of logins — e.g. `["team-lead", "qa-bot"]`.
- a list that **mixes in** `assignees` — e.g. `["assignees", "project-manager"]` pings the card's assignees *and* the extra people (a reviewer, a PM). Duplicates are removed.

Run it on a cadence:

```yaml
on:
  schedule:
    - cron: "0 9 * * 1-5"   # weekday mornings
```

## What happens

For each rule, any card whose status hasn't changed in more than `days` gets a comment that @-mentions the people named in `notify` — its assignees, an explicit list, or both. The message supports `{days}`, `{status}`, `{number}`, and `{title}` placeholders.

**No spam:** each nudge embeds a hidden marker. The card won't be nudged again until its status actually changes, so daily runs won't re-ping the same stale card.

## Tips

- "Time in status" is based on when the Status field last changed, not comment activity — a card people are chatting on but not *moving* still counts as stale (usually what you want).
- Want a harder escalation after the nudge is ignored? See [use case 12](./12-escalation-with-revert.md).
