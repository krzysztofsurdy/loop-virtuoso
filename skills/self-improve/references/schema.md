# Learning file schema

One learning per file under `learnings/`, named `<slug>.md`. A file is YAML
frontmatter plus a short body. Keep the body to the reasoning a future run needs,
not a retelling of the run.

## Contents

- [Frontmatter](#frontmatter)
- [The two tracks](#the-two-tracks)
- [retire_when](#retire_when)
- [Body](#body)
- [Example](#example)

## Frontmatter

Always required:

| Field | Meaning |
|---|---|
| `module` | The area it applies to (a path prefix, package, or subsystem). Used by retrieval. |
| `date` | ISO date the learning was written. |
| `problem_type` | A short kebab-case category (for example `flaky-test`, `migration-order`, `api-contract`). |
| `component` | The concrete thing involved (a file, command, service, or config key). |
| `severity` | `low`, `medium`, or `high`: how much a repeat would cost. |

## The two tracks

A learning is one of two kinds. Add the track's extra fields.

**Bug track** (something broke and the cause was not obvious from the fix):

| Field | Meaning |
|---|---|
| `symptoms` | 1 to 5 observable signs, as a list. What a future run would see. |
| `root_cause` | One line: the actual cause, not the symptom. |

**Knowledge track** (a convention, constraint, or decision that is not visible in
the code):

| Field | Meaning |
|---|---|
| `applies_when` | The condition under which this learning is relevant, so retrieval can match it. |

## retire_when

Optional on either track. An external condition that makes the learning obsolete,
plus how to check it, so `/improve` can delete it instead of carrying it forever.
For example: an upstream issue closed as fixed, a dependency reaching a version, a
workaround whose feature shipped. Write the condition and the check, not a date.

A list item that starts with a YAML indicator character (for example `-`, `:`, `?`)
must be quoted.

## Body

A few lines of the reasoning that the final code, tests, and docs do not already
carry. If the body only restates what the diff shows, the learning should not
exist (see the durability gate in [improve.md](improve.md)).

## Example

```markdown
---
module: app/billing
date: 2026-10-27
problem_type: migration-order
component: db/migrations/0042_add_invoice_status.sql
severity: high
applies_when: adding a NOT NULL column to a table with live writers
retire_when:
  condition: the deploy pipeline runs expand/contract migrations in separate releases
  check: grep the pipeline config for a two-phase migration step
---

Adding the column and backfilling in one migration locked the invoices table long
enough to time out live writers. The fix was expand then contract across two
releases. The code shows the final two-phase migration but not why a single
migration is unsafe here, which is the live-writer contention on this table.
```
