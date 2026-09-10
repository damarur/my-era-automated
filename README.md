# my-era-automated

Automates daily clock in/out on [MyEra](https://hcs.eratime.eu) using GitHub Actions, so you don't have to remember to do it manually.

## Schedule (Europe/Madrid)

| Workflow | When |
|---|---|
| `clock-in.yml` | Every day at 08:00 |
| `clock-out.yml` | 17:00 Monday–Thursday, 14:00 Friday |

GitHub Actions cron only runs in UTC, so each workflow is scheduled for both possible UTC offsets (CET/CEST) and a guard step checks the actual Madrid local time before doing anything, skipping the run that doesn't match. This keeps the schedule correct across DST changes without duplicate clock-ins/outs.

Both workflows can also be run manually from the **Actions** tab (`workflow_dispatch`).

## Setup

Add two repository secrets with your MyEra credentials:

**Settings → Secrets and variables → Actions → New repository secret**

| Secret | Value |
|---|---|
| `ERA_USER` | your MyEra user code |
| `ERA_PASS` | your MyEra password |

No other configuration is needed — the workflows in `.github/workflows/` pick them up automatically.

## Skipping absences

To stop clock-in/clock-out on specific days (e.g. sick leave, vacation), add a line to `absences.txt`:

```
2026-09-15
2026-09-21:2026-09-25
```

Single dates or inclusive `start:end` ranges, one per line. Commit the change (or edit directly on GitHub) before the next scheduled run — no need to disable the workflow.

## How it works

Each run:
1. Logs in to MyEra with the credentials above and extracts the `Hcs-Token` auth header.
2. Calls the clocking endpoint with `TYPE=1` (clock in) or `TYPE=2` (clock out) using that token.

## Local testing

`era-time.http` contains the same two requests for manual testing with an HTTP client (e.g. the IntelliJ/VS Code HTTP client). It is git-ignored since it's meant to hold your real credentials locally — never commit it.
