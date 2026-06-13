---
name: setup-project
description: Per-project bootstrapper for the ai-product-builder workflow. Initializes a new repo with CLAUDE.md, scaffolds feature_list.json, progress.md, and runs init.sh. Use this whenever starting a fresh project that should follow the product-builder pipeline — even if the user just says "set up this project" or "get this repo ready."
---

# Setup Project

Bootstrap a new project to use the ai-product-builder workflow.

## Steps

1. Copy `templates/feature_list.json` → `feature_list.json`
2. Copy `templates/progress.md` → `progress.md`
3. Copy `templates/init.sh` → `init.sh` and make it executable
4. Create `CLAUDE.md` at project root — ask the user for project name, stack, and first features if not already known
5. Run `bash init.sh`
6. Confirm the feature backlog with the user before closing
