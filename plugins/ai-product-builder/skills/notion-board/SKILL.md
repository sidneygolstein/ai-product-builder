---
name: notion-board
description: >-
  Read and write the Ticket Backlog in Notion via MCP. Use for ticket operations:
  creating tickets from a spec, querying what to work on next, updating status at pipeline
  gates, syncing with ai/feature_list.json. Trigger on "ticket", "Ticket Backlog",
  "what's next ticket", or any explicit status transition (TO DO, DOING, TO REVIEW,
  TO DEPLOY, DONE). Do NOT use for Notion wikis, meeting notes, or decision pages.
---

# Notion Board

How to interact with the Ticket Backlog database for the ai-product-builder pipeline.

Do not guess property names or status values — every field name and status string in this skill is exact and case-sensitive.

## Notion is optional — check first

Before ANY Notion operation, read `notion_enabled` from `ai/config/notion.json`.

- `notion_enabled` is `false`, or the file is missing: **make no MCP calls at all.**
  `ai/feature_list.json` is the sole source of truth — perform every read, create, and
  status update there directly, then return. Everything below this section applies only
  when Notion is enabled.
- `notion_enabled` is `true` or absent from an otherwise-populated config (legacy
  projects): Notion is the system of record — follow the rest of this skill exactly.

## MCP tools

Use only these tools. Do not use WebFetch or the Notion REST API directly.

| Operation | Tool |
|---|---|
| Query tickets (filtered) | `mcp__notion__notion-query-database-view` |
| Search ticket by title | `mcp__notion__notion-search` |
| Read one ticket | `mcp__notion__notion-fetch` |
| Create ticket | `mcp__notion__notion-create-pages` |
| Update status or property | `mcp__notion__notion-update-page` |

## Identifiers

Required before any Notion call. Read from `ai/config/notion.json`:

```json
{
  "notion_enabled": true,
  "ticket_db_id": "<Notion database UUID>",
  "project_id":   "<Notion project page UUID>"
}
```

If `notion_enabled` is true but `ticket_db_id` or `project_id` is missing or empty, stop and ask the user — do not search Notion blindly.

## Database properties

Every ticket has exactly these eight properties — no others:

| Property | Type | Values / notes |
|---|---|---|
| **Title** | text | `[F<n>] Short imperative description` |
| **Type** | select | `Feature` · `Bug` · `Tech` · `Discovery` |
| **Feature** | text | Feature slug — must match `feature` field in `ai/feature_list.json` |
| **Status** | select | Exact values from the status flow table — case-sensitive, no substitutions |
| **Technical Shape** | select | `ui` · `backend` · `trivial` |
| **Project** | relation | Relation to the project page — use `project_id` from `ai/config/notion.json` |
| **Acceptance Criteria** | text | Newline-separated testable ACs covering: populated · missing/legacy · loading · flag-off |
| **Refs** | text | Stringified JSON: `"{\"prd\":\"docs/brainstorms/...\",\"design\":\"docs/design/...\",\"notion\":\"<url>\"}"` — always `JSON.stringify` before writing |

## Status flow

```
TO SPEC REVIEW → TO DO → DOING → TO REVIEW → TO DEPLOY → DONE
```

Status values are **case-sensitive** — copy them verbatim from this table. Do not title-case, lowercase, or substitute underscores.

| Status | Meaning | Who sets it (when running this skill) |
|---|---|---|
| `TO SPEC REVIEW` | Created, awaiting spec-reviewer | You, via `/tickets` |
| `TO DO` | Spec approved at Gate 1 | You, on human go |
| `DOING` | `/plan` approved, worktree created | You, at Gate 2 |
| `TO REVIEW` | Verifier returned `pass` | You, after verifier pass |
| `TO DEPLOY` | Simplifier attested no behaviour change | You, after simplifier |
| `DONE` | PR merged, Gate 3 human approval | You, after merge |

Never skip a status. Never move backward without explicit human instruction.

## Reading the board

Always filter by `Project` using `project_id` — never query unscoped.

When the user asks "what's next": return the **single highest-priority ticket** using this order — any ticket in `DOING` first; if none, the oldest in `TO DO`; if none, the oldest in `TO SPEC REVIEW`. Return one ticket, not a list.

## Creating a ticket

> **`Project` is mandatory on every ticket — no exceptions.**
> This includes Bug tickets, Tech tickets, Discovery tickets, and any follow-up tickets opened mid-pipeline.
> Always read `project_id` from `ai/config/notion.json` and set the relation before creating.
> A ticket without `Project` will not appear in the board filter and is effectively lost.

1. Read `project_id` from `ai/config/notion.json`.
2. Draft all eight properties — Title, Type, Feature, Status, **Technical Shape**, **Project** (using `project_id`), Acceptance Criteria, Refs.
3. Show the draft as a markdown table and wait for explicit confirmation ("yes", "go", "ok") before calling `mcp__notion__notion-create-pages`.
4. On confirmation, create in Notion first, then update `ai/feature_list.json`.

## Status transition protocol

Every status change — by any command or agent — must follow this exact sequence. Never shortcut it.

```
BEFORE transitioning:
  1. Read ai/config/notion.json for ticket_db_id and project_id. If you already read it
     earlier in this session, reuse the cached value — do not re-fetch.
     Get notion_page_id for the ticket from ai/feature_list.json.
  2. Confirm the ticket's current status matches the expected "from" status (never skip forward)

TO TRANSITION:
  3. Call mcp__notion__notion-update-page with the ticket's notion_page_id and new Status value
  4. On success → update the ticket's "status" field in ai/feature_list.json
  5. On any failure at step 4 → write ai/decisions/divergence-<timestamp>.md, report, stop
```

The write order (Notion first, local second) is intentional: Notion is the system of record. Both stores must never diverge. If local write fails, the divergence file preserves what happened. Never reverse the order.

## ai/feature_list.json ticket schema

```json
{
  "id": "F6.1",
  "feature": "<slug — matches Notion ticket Feature property, e.g. 'user-search'>",
  "title": "Short imperative description",
  "status": "TO DO",
  "technical_shape": "ui | backend | trivial",
  "notion_page_id": "<Notion page UUID>",
  "branch": "feature/<feature>-F6.1",
  "worktree": ".worktrees/F6.1",
  "acceptance_criteria": [
    "populated state renders",
    "missing/legacy state",
    "loading state",
    "flag-off hides section"
  ],
  "definition_of_done": [
    "baseline check passes",
    "all ACs green",
    "decision record written"
  ],
  "refs": {
    "prd": "docs/brainstorms/...",
    "design": "docs/design/...",
    "notion": "<url>"
  }
}
```

## Done when

Both the Notion page `Status` and the matching `ai/feature_list.json` ticket `status` reflect the same value. Return the Notion page ID and the updated ticket ID to the caller.
