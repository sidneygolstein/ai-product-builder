# Notion ID Lookup — Worked Example

## Why this matters

There are two distinct kinds of UUID in Notion responses:

| Kind | What it is | Where to use it |
|------|-----------|-----------------|
| Page UUID | UUID of a Notion page or database entry | `notion-fetch`, relation fields |
| Data-source UUID | UUID from a `collection://` URL | `notion-query-database-view` queries |

Confusing these is the most common failure. `notion-query-database-view` requires a
data-source UUID — passing a page UUID returns "object not found" with no clear diagnostic.

---

## Step-by-step: extract ticket_db_id

### 1. Search for the Ticket Backlog

```
mcp__notion__notion-search  query="Ticket Backlog"
```

The response lists pages and databases. Show the results to the user and ask: "Is this the
right Ticket Backlog?" Pick the confirmed result and note its URL.

### 2. Fetch the database to extract the data-source UUID

```
mcp__notion__notion-fetch  id="<confirmed page URL>"
```

Look for a `<data-source url="collection://...">` tag in the response. Example:

```xml
<data-source url="collection://12345678-90ab-cdef-1234-567890abcdef">
  <properties>...</properties>
</data-source>
```

Extract the UUID after `collection://` — this is `ticket_db_id`.

---

## Repeat for projects_db_id

Same two calls on the Projects database. The user may need to paste the URL if search
returns multiple results.

---

## project_id

`project_id` is different from both of the above. It is the **page UUID** of this
project's specific row in the Projects database — not the database itself.

- Before Step 7: write `""` as a placeholder.
- After Step 7 creates or finds the row: update with the returned page UUID.

---

## If the user cannot find the database

Ask: "Please paste the Notion URL of the Ticket Backlog." Use that URL directly in
`notion-fetch`. Never guess or construct URLs.

---

## Summary

```
ticket_db_id    = UUID from collection:// URL of Ticket Backlog database
projects_db_id  = UUID from collection:// URL of Projects database
project_id      = page UUID of THIS project's row in Projects database (set after Step 7)
backlog_key     = string value used in the Project property to filter tickets (informational)
```
