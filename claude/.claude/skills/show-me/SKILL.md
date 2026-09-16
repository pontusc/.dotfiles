---
name: show-me
description: Help the user understand the current topic visually by building one focused HTML page of diagrams and code-shape sketches, then opening it in the browser.
---

Help the user understand the current topic of conversation visually. The terminal prints markdown as plain text, so nothing renders there: no Mermaid, no styled blocks, no images. Build the answer as one focused HTML file and open it:

```
Bash(open path/to/show-me-{description}.html)
```

Everything goes in the page. Skip the preamble, keep prose brief, and pick the smallest view that makes the key point clear. In the terminal, say what you built and where it is, nothing more.

### what to show

The code-shaped forms below belong in the page as monospace blocks. Keep their exact text shape, style them, and do not redraw them as boxes.

- Show logic or an algorithm as pseudocode:

```text
on(save)
  if content is unchanged
    return cached result
  write new content
  return fresh result
```

- Show runtime control flow as a call tree:

```text
submitForm
  createSession
    persistPrompt
    launchAgent
  navigateToSession
```

- Show UI structure as a component tree, including state and module boundaries that matter:

```tsx
<SessionPage> (apps/example/src/routes/session.tsx)
  useSessionEvents()
  <SessionToolbar>
    <RunSkillButton> (packages/ui)
```

- Show file responsibility or a broad refactor as a shallow file tree:

```text
src/
├── commands/       # parses user actions
├── sessions/       # owns session state
└── transport/      # sends API requests
```

- Use `diff` when the point is what changes and the surrounding shape already exists. Match the diff shape to the topic, and colour the added and removed lines in the page.

For a component change:

```diff
 <SessionPage>
   useSessionEvents()
   <SessionToolbar>
+    <RunSkillButton />
   <SessionTimeline>
+    <SkillResultCard />
```

For a file-layout change:

```diff
 src/
 ├── commands/
+│   └── show-me.ts       # expands the slash command
 ├── sessions/
-└── transport.ts
+└── transport/
+    ├── client.ts
+    └── stream.ts
```

For a call-tree or call-stack change:

```diff
 submitForm
   createSession
     persistPrompt
+    expandSkillMention
     launchAgent
-  navigateToSession
+  navigateToSession
+    subscribeToEvents
```

For a state or control-flow change:

```diff
 on(save)
-  write content
+  if content is unchanged
+    return cached result
+  write new content
+  invalidate cache
```

- Show the whole block when most of it is new, when omitted context would hide ownership or order, or when the user needs a copyable target shape:

```ts
function expandSkill(command: string): string {
  const skillName = command.slice(1)
  return `use the ${skillName} skill`
}
```

- Draw anything pictorial for real, as HTML and CSS or inline SVG: component interaction, control flow, data flow, sequence and lifecycle, a UI or layout, a state comparison, an infographic, a short slide deck. Boxes, arrows, and lanes carry these, not indented text.

### guidance

Place each visual next to the short text it supports. Keep only the calls, files, props, states, and boundaries needed to answer the user's current question or the options to resolve the current discussion point.

You may use one of these forms, you may use several, it is unlikely you will use all of them. Use your judgement and don't overwhelm the user.

Build the page itself with the same restraint. Match the product's colors, type, and spacing, use real labels and data, support desktop and mobile, and keep it to one file with no build step.
