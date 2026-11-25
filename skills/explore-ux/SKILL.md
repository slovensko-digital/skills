---
name: explore-ux
description: Explore UX/UI options for one piece of functionality as static HTML pages, isolated from the rest of the app, kept in a dated `explorations/` folder with the problems, ideas, options, decision and every round. Use this whenever the user wants to explore, prototype, mock up, sketch or compare ways to improve or design an input, form, component, page or flow before (or instead of) changing the real app, says "let's explore…", "show me options for…", "how could X look/work", or wants to continue or revisit an earlier exploration.
---

# Explore UX

Build throwaway, clickable options for one UX problem next to the app, not inside it.
Each exploration is a dated folder with static pages that look exactly like the app
(the app's own compiled CSS, fonts and markup), plus an `index.html` that records why
it exists, what was tried and what was chosen. Months later anyone can open it and see
the options that were on the table and how the choice evolved.

One exploration = one thing being explored. Follow-up prompts are **rounds** of the
same exploration, not new explorations.

## Layout

```
explorations/
  20261123103245_preferred_places/   # UTC timestamp of the first prompt + snake_case name
    index.html                       # the record: prompt, problems, ideas, options, decision, rounds
    0-current.html                   # today's behaviour, 1:1 with production
    a-<slug>.html, a2-<slug>.html, b-<slug>.html …
    assets/                          # frozen copy of the app's compiled CSS + fonts; proto.css for the few extras
    js/                              # option behaviour
```

- The folder is committed to the repo. It is the history.
- Assets are copied, not linked, so an old exploration keeps the look it had.
- No README: everything goes into `index.html`.

## Workflow

### 1. Make sure explorations are served

The dev server serves `explorations/` so people browse it at `/explorations`
(a one-line-per-exploration listing) and `/explorations/<folder>/`.

- **Rails:** if `/explorations` is not routed yet, copy
  [rails/explorations_controller.rb](rails/explorations_controller.rb) to
  `app/controllers/` and add, next to other development-only routes and before any
  catch-all route:

  ```ruby
  if Rails.env.development?
    get "explorations" => "explorations#index"
    get "explorations/*path" => "explorations#show", format: false
  end
  ```

  The listing ships unstyled. Style it with the app's own stylesheet and classes,
  keeping the layout: one row per exploration, date and name as the link on the left,
  note and status on the right.
  Tell the user this is a one-time setup and part of the change to commit.
- **Other stacks:** serve the folder the way the dev server serves static files
  (development only), or as a last resort `python3 -m http.server` from `explorations/`.

Once `/explorations` is set up, leave it as it is: do not change the listing's markup or
styling, the controller or the routes in later runs. The same goes for the exploration
pages' shell (top bar, note box, index page): new explorations copy the shell of the
latest existing exploration instead of restyling it.

### 2. Problems and ideas

The exploration starts from **problems**, not solutions.

- If the user gave no problems, ask for them (what is hard, confusing or slow today, and
  for whom). Do not invent the problems.
- If the user gave no ideas, look at the current screen and suggest 2–4 distinct
  directions, each in one line, and let the user pick which to build
  (AskUserQuestion, multi-select). If the user gave ideas, build those and add at most
  one or two suggestions of your own, marked as suggested.

### 3. Study the real thing

Before writing a page, read the real view/template, its partials, the CSS that styles it
and its JS. Open the live page in the browser if one is available.

- Copy the compiled CSS (e.g. `app/assets/builds/application.css`) and the fonts it
  references into `assets/`; fix font URLs to relative paths.
- Use the app's real markup, class names and form field names, so an option can move
  into the app with little rewriting.
- **JS:** use the app's frontend framework only if the app uses it. Stimulus only when
  the app uses Stimulus (check `config/importmap.rb` / `package.json`) — vendor the same
  version into `js/`. Otherwise plain ES modules.
- **All styling comes from the repo the skill runs in.** This skill ships no CSS. The
  exploration's own chrome (top bar, note box, index page, option cards) is built from
  the app's existing components, classes, colours, fonts and spacing: reuse a nav, a
  notice/alert and a card the app already has. Look at how the app styles them before
  writing anything.
- Only what the app has no equivalent for goes into `assets/proto.css`, written with the
  app's own values (colour variables, font, radii). Never edit the copied app CSS.

### 4. Build the pages

- **`0-current.html`** reproduces today's behaviour 1:1, bugs included. It is the
  baseline; do not improve it.
- One page per option: `A`, `B`, `C` … for distinct directions; `A2`, `A3` … for
  variations of A. Titles are short, in the app's language (`A2 · Pilulky ako vo filtri`).
- Every page has:
  - a top bar: `Explorations` (→ `/explorations`), the exploration name (→ `index.html`),
    then every option, current one highlighted;
  - a short note box above the component: what this option does, what to try
    (e.g. "type xyz for the not-found state"), known trade-offs;
  - realistic data that shows the problem (enough items to overflow, long names,
    duplicates, the empty state);
  - the submit button showing the payload the form would send, when it is a form.
- Cover the states people forget: empty, not found, many items, long text, keyboard
  (Esc, Enter, Backspace), click outside, mobile width.
- When many pages share one shell, a small generator script (e.g. `build.py`) is fine;
  it must never overwrite `index.html`.

### 5. Write `index.html`

Start from [index-template.html](index-template.html). It contains, in order:

1. Title and a meta line: started (UTC), page/field explored, status.
2. **Prompt:** the user's first prompt, verbatim, in a `<pre>`.
3. **Problems:** cleaned-up list.
4. **Ideas:** each marked *User* or *Suggested*, with the options it led to (→ A, B).
5. **Options:** one card per page, one-line description. Mark the chosen one, and add
   "Not chosen" / "Parked" to the others once decided.
6. **Decision:** what was chosen (or combined) and why, known trade-offs, link to the PR.
7. **Rounds:** newest first, `YYYY-MM-DD HH:MM` (UTC) and one or two lines each.

Status lives in two meta tags the listing reads:

```html
<meta name="exploration-status" content="open">   <!-- open | chosen | dropped -->
<meta name="exploration-note" content="A4, implemented in PR #102">
```

- `open` while exploring; `chosen` when the user picks one or combines several
  (note says which: `A4`, `A2 + C`); `dropped` when the idea is abandoned (note says why).
- `PR #123` in the note becomes a link to the pull request in the listing.

### 6. Rounds

Every follow-up prompt in the exploration is a round:

- Add an entry at the top of **Rounds** with the time and what changed, including
  answers to questions (e.g. "WCAG check: 3.62:1 failed, raised to 75 %").
- A new direction or variation gets a new page (`A3`); do not overwrite an option the
  user has seen, unless they ask to fix it. Fixes to all options are one round entry.
- Never delete option pages. Parked options stay listed so the comparison stays honest.
- When the user decides, update **Decision**, the option cards and the status meta.

### 7. Check and hand over

- Open every new or changed page in the browser if available, try the interaction,
  look at the not-found/empty states.
- Reply with the link (`/explorations/<folder>/` on the dev server) and what to look at,
  one line per option. Mention trade-offs you noticed and which option you would pick.

## Rules

- Do not change the app's own code while exploring, except the one-time serving setup.
  After setup, never change the listing's or the shell's styling.
  Implementing the chosen option is a separate step the user asks for; the exploration
  folder stays as it is and gets a round entry and the PR link.
- Accessibility counts: check contrast of any new colour against WCAG AA and say so in
  the round entry.
- Timestamps are UTC, like Rails migrations.
