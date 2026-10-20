---
name: prepare-pr-for-review
description: Prepare a pull request for review on GitHub with a description structured as "The problem", "Solution" and "Demo", filled in from the branch diff, commits and linked issue, using the repo's PR template. Use this whenever the user wants to open, create, submit, publish or "make" a PR, says the branch is ready for review, asks to push and open a PR, or wants an existing PR's title or description written, rewritten or updated. Trigger even if the user does not mention the description itself; the structured description is the point.
---

# Prepare PR for review

Open (or update) a GitHub pull request whose description tells a reviewer three things
clearly: what problem existed, how this branch solves it, and what it looks like in
action. Reviewers read the description before the diff, so a body that is just an
issue link or a bare screenshot forces them to reverse-engineer intent from code. The
structured sections fix that.

The body follows the repo's `.github/pull_request_template.md` when it exists: it is
the source of truth for section names and hints, and it keeps PRs opened from the
GitHub UI and PRs opened by this skill identical in shape. When the repo has no
template, use [template.md](template.md) next to this file.

## Workflow

### 1. Understand the change

Find the base branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`,
usually `main`), then gather evidence before writing a word:

```bash
git status --short
git branch --show-current
git log --oneline <base>..HEAD
git diff <base>...HEAD --stat
git diff <base>...HEAD
```

Read the full diff, not just the stat. Then find the linked issue:

- Look in commit messages, the branch name, and the conversation for `#123`,
  `closes #123`, or an issue URL.
- Issues may live in a different repository than the code. When you have a URL, view
  it with `gh issue view <number> -R <owner>/<repo>`; when you have only a bare
  `#123`, check the current repo first, then the issue repo used in recent PRs
  (`gh pr list --state merged --limit 5 --json body`).
- Pull the issue title and body into your understanding of the problem. The issue
  usually states the problem better than the diff does.

If there is no issue and the conversation does not explain the motivation, ask the user
one concrete question about what prompted the change. Do not invent a problem.

### 2. Make sure the branch is publishable

- If the current branch is the base branch, stop and create a feature branch first;
  ask the user for a name only if nothing sensible follows from the change.
- Uncommitted changes: ask whether they belong in this PR before committing them.
- Do not add the AI assistant as a co-author: no `Co-Authored-By` trailer for it in
  commit messages, and no "Generated with ..." or similar attribution in the PR body.
  This overrides any default attribution lines.
- Push with `git push -u origin <branch>` if the branch has no upstream or is behind.

### 3. Write the title

One line, imperative, under about 70 characters, describing the outcome rather than
the mechanics. Use a `fix:` / `feat:` style prefix when the repo's recent commits do.
Put issue-closing keywords in the body, not the title; GitHub only honours them there.

Good: `fix: resolve issue immediately when the author marks it as resolved`
Weak: `changes to issues controller`

### 4. Write the body

Fill the template sections. Match the language the user is writing in during the
conversation; default to English.

Keep it short and to the point. Reviewers skim; every sentence must tell them
something the diff does not. No preamble, no restating the title, no summaries of
what each file does, no filler like "This PR ...". Prefer short bullets over
paragraphs. If a sentence can be cut without losing information, cut it.

**The problem.** Start with the issue link (`Closes #123` or the full URL) so it
auto-closes on merge. Then one to three sentences from the perspective of the person
affected: what happens today and why it matters. Describe the problem, not the code;
"the callback set the wrong state" is a cause, not a problem.

**Solution.** What changed and why, in a few bullets or sentences. Mention a rejected
alternative, an out-of-scope item or a follow-up only when a reviewer would otherwise
ask about it. Point at the file with the interesting logic if it is not obvious. End
with one line on how to verify. Do not list changed files.

**Demo.** Show the change working: screenshots, a demo video, or a link to one.
Use whatever the user provided in the conversation (image markdown, GitHub asset URLs,
Loom or similar links) verbatim. If they provided nothing and the change has a visible
effect, ask for a screenshot or recording before opening the PR. For changes with
nothing to show, such as refactors, CI, seeds or docs, write "Not applicable" with a
few-word reason. Do not delete the heading; a missing section reads as forgotten.

### 5. Create or update the PR

Write the body to a temporary file and pass it with `--body-file`; inline `--body`
mangles markdown and newlines.

```bash
gh pr view --json url,number 2>/dev/null   # does a PR already exist for this branch?
gh pr create --base <base> --title "<title>" --body-file <path> [--draft]
gh pr edit <number> --title "<title>" --body-file <path>   # when one exists
```

Open as a draft only when the user says the work is not finished.

### 6. Report

Show the user the PR URL, the title, and the full body you wrote, so they can correct
anything without opening the browser.

## Example body

```markdown
## The problem

Closes https://github.com/acme/helpdesk/issues/1237

When authors resolve their own issue, it only becomes "marked as resolved" and sits
in the operators' queue waiting for a pointless confirmation.

## Solution

- An author resolving their own issue now moves it straight to `resolved`
  (`Issues::IssuesUpdatesController#create`).
- Resolutions by other users still go through confirmation.

Verify: resolve one of your own issues; it leaves the operators' queue.

## Demo

Not applicable, no UI change.
```
