# Plan: SharkerSkills Plugin Bootstrap (v0.1.0)

**Status:** APPROVED via Ralplan consensus (Planner → Architect ITERATE → Planner revise → Critic ITERATE → Planner revise → Critic APPROVE)
**Spec:** `.omc/specs/deep-interview-sharker-skills-plugin.md`
**Working dir:** `/Users/sharker/Desktop/Project/Person/AI/Tool/SharkerSkills/`

---

## Naming Convention (pinned)
- **GitHub repository:** `Sharker/SharkerSkills` (PascalCase)
- **Plugin / marketplace identifier:** `sharker-skills` (kebab-case) — used in BOTH manifests; this is the string users type at install.

---

## RALPLAN-DR

### Principles
1. Parity over invention — mirror oh-my-claudecode's `.claude-plugin/` layout
2. Honest versioning — pre-1.0 signals instability
3. Reproducibility of intent — `.omc/specs/` and `.omc/plans/` ship with repo
4. Source-of-truth single-copy — SKILL.md inside plugin repo is canonical
5. Minimum viable surface — ship one working skill correctly

### Decision Drivers
1. Installable via `/plugin marketplace add Sharker/SharkerSkills` on a clean machine
2. Future-skill additions require zero structural changes
3. Discoverability metadata sufficient for marketplace listing

### Options
- **A (CHOSEN):** Single multi-skill plugin `sharker-skills` with `skills: "./skills/"` glob
- **B:** Single-skill plugin `sharker-ios-store-assets` — invalidated (rename later breaks users)
- **C:** One plugin per skill — invalidated (premature for N=1)

---

## File Tree

```
SharkerSkills/
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── skills/
│   └── ios-store-assets/
│       ├── SKILL.md
│       └── ... (all subdirs preserved)
├── .omc/
│   ├── specs/   (tracked)
│   └── plans/   (tracked)
├── .gitignore
├── LICENSE      (MIT, 2026 Sharker)
└── README.md
```

---

## Final Manifests

### `.claude-plugin/marketplace.json`
```json
{
  "$schema": "https://raw.githubusercontent.com/anthropics/claude-code/main/schemas/marketplace.json",
  "name": "sharker-skills",
  "description": "Sharker's curated personal Claude Code skill collection.",
  "owner": {
    "name": "Sharker",
    "email": "aaksharker@gmail.com"
  },
  "version": "0.1.0",
  "plugins": [
    {
      "name": "sharker-skills",
      "description": "A growing collection of focused, reusable Claude Code skills curated by Sharker. Seeded with ios-store-assets.",
      "version": "0.1.0",
      "author": {
        "name": "Sharker",
        "email": "aaksharker@gmail.com"
      },
      "source": "./",
      "category": "productivity",
      "homepage": "https://github.com/Sharker/SharkerSkills",
      "tags": ["skills", "ios", "app-store", "assets", "personal-collection"]
    }
  ]
}
```

### `.claude-plugin/plugin.json`
```json
{
  "name": "sharker-skills",
  "version": "0.1.0",
  "description": "A growing collection of focused, reusable Claude Code skills curated by Sharker. Seeded with ios-store-assets.",
  "author": {
    "name": "Sharker",
    "email": "aaksharker@gmail.com"
  },
  "repository": "https://github.com/Sharker/SharkerSkills",
  "homepage": "https://github.com/Sharker/SharkerSkills",
  "license": "MIT",
  "keywords": ["skills", "ios", "app-store", "assets", "claude-code"],
  "skills": "./skills/"
}
```

**Intentional shape decisions:**
- No `mcpServers` — skills-only plugin
- No `$schema` on `plugin.json` — parity with oh-my-claudecode
- `author: {name, email}` (with email) — deliberate divergence from reference for bug-report routing
- `category: "productivity"` matches reference enum; `"skills"` retained as tag

---

## Execution Steps

### Step 1 — Source Skill Portability Audit
```bash
grep -RnE '/Users/|~/\.claude|/home/|\$HOME|expanduser|os\.path\.expanduser|process\.env\.HOME' /Users/sharker/.claude/skills/ios-store-assets/
```
For each match: replace with plugin-relative path (`${CLAUDE_PLUGIN_ROOT}/...` or `./...`).

### Step 2 — Scaffold
```bash
mkdir -p /Users/sharker/Desktop/Project/Person/AI/Tool/SharkerSkills/.claude-plugin
mkdir -p /Users/sharker/Desktop/Project/Person/AI/Tool/SharkerSkills/skills
```

### Step 3 — Write Manifests (verbatim from above)

### Step 4 — Recursive Copy + Patch
```bash
cp -R /Users/sharker/.claude/skills/ios-store-assets/. /Users/sharker/Desktop/Project/Person/AI/Tool/SharkerSkills/skills/ios-store-assets/
```
Apply Step 1 patches in destination (never source).

### Step 5 — JSON Validation
```bash
jq . .claude-plugin/marketplace.json
jq . .claude-plugin/plugin.json
```

### Step 6 — Author README, LICENSE, .gitignore

**`.gitignore`:**
```
.DS_Store
*.log
node_modules/
```

**`LICENSE`:** Standard MIT text, `Copyright (c) 2026 Sharker`.

**`README.md` install block (verbatim):**
```
/plugin marketplace add Sharker/SharkerSkills
/plugin install sharker-skills@sharker-skills
```
Plus tagline, skill catalog, versioning note.

### Step 7 — 14-Row Acceptance Verification

| # | Check | Command |
|---|---|---|
| 1 | Marketplace JSON parses | `jq . .claude-plugin/marketplace.json` |
| 2 | Plugin JSON parses | `jq . .claude-plugin/plugin.json` |
| 3 | Marketplace required keys | `jq -e '.["$schema"] and .name and .description and .owner.name and .owner.email and .version and (.plugins \| length > 0)' .claude-plugin/marketplace.json` |
| 4 | Plugin entry required keys | `jq -e '.plugins[0] \| .name and .description and .version and .author.name and .author.email and .source and .category and .homepage and .tags' .claude-plugin/marketplace.json` |
| 5 | plugin.json required keys | `jq -e '.name and .version and .description and .author.name and .author.email and .repository and .homepage and .license and .keywords and .skills' .claude-plugin/plugin.json` |
| 6 | No mcpServers | `jq -e '.mcpServers == null' .claude-plugin/plugin.json` |
| 7 | No $schema on plugin.json | `jq -e '.["$schema"] == null' .claude-plugin/plugin.json` |
| 8 | SKILL portable | `! grep -RnE '/Users/\|~/\.claude\|/home/\|\$HOME\|expanduser' skills/ios-store-assets/` |
| 9 | .omc/ tracked | `! git check-ignore .omc/plans/sharker-skills-bootstrap.md` |
| 10 | Versions match across 3 sites | `[ "$(jq -r .version .claude-plugin/marketplace.json)" = "$(jq -r .version .claude-plugin/plugin.json)" ] && [ "$(jq -r .version .claude-plugin/marketplace.json)" = "$(jq -r .plugins[0].version .claude-plugin/marketplace.json)" ]` |
| 11 | README install block | `grep -F '/plugin marketplace add Sharker/SharkerSkills' README.md && grep -F '/plugin install sharker-skills@sharker-skills' README.md` |
| 12 | category=productivity | `jq -e '.plugins[0].category == "productivity"' .claude-plugin/marketplace.json` |
| 13 | Plugin name kebab in all 3 sites | `[ "$(jq -r .name .claude-plugin/plugin.json)" = "sharker-skills" ] && [ "$(jq -r .plugins[0].name .claude-plugin/marketplace.json)" = "sharker-skills" ] && [ "$(jq -r .name .claude-plugin/marketplace.json)" = "sharker-skills" ]` |
| 14 | LICENSE/SPDX match | `grep -q '^MIT License' LICENSE && [ "$(jq -r .license .claude-plugin/plugin.json)" = "MIT" ]` |

### Step 8 — Manual Smoke Test (after implementation)
In a fresh Claude Code session:
```
/plugin marketplace add /Users/sharker/Desktop/Project/Person/AI/Tool/SharkerSkills
/plugin install sharker-skills@sharker-skills
/reload-plugins
```
Verify `ios-store-assets` appears in skill registry.

### Step 9 — Git Init + First Commit (deployment)
```bash
git init -b main
git add .
git commit -m "feat: initial sharker-skills plugin with ios-store-assets"
```

---

## ADR

**Decision:** Single multi-skill plugin `sharker-skills@0.1.0`, GitHub marketplace `Sharker/SharkerSkills`, MIT license, seeded with `ios-store-assets`.

**Why chosen:** Only option satisfying all 3 drivers. Plural name reflects forward-looking intent.

**Consequences (accepted):**
- Plugin-wide releases only (no per-skill versioning)
- Multi-plugin growth would require monorepo restructure or extraction
- Author email publicly exposed (intentional parity break for bug routing)

**Follow-ups:**
1. Create github.com/Sharker/SharkerSkills + push
2. Run Step 8 smoke test
3. v0.2.0 when skill #2 lands; v1.0.0 only after stability cycle
