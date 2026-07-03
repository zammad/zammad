// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * Multi-addon weave rule discovery.
 *
 * Each installed addon ships its own `*.weave.mjs` manifest next to its frontend
 * code (linked into `app/frontend` on install). Core lists nothing and knows
 * about no addon: this globs every manifest under `app/frontend`, imports it, and
 * concatenates the exported rules. Any number of addons compose; adding one is
 * dropping a manifest, never editing a shared core file.
 *
 * A manifest exports `addonWeaveRules` (or a default export): an array of rules
 * consumed by plugin.mjs.
 */

import { globSync } from 'node:fs'
import { resolve } from 'node:path'
import { pathToFileURL } from 'node:url'

// Anchor on the project root (Vite/Vitest run from it). `import.meta.url` is
// unreliable here because Vite bundles the config to a temp file before running.
const frontendRoot = resolve(process.cwd(), 'app/frontend')

export const discoverAddonWeaveRules = async () => {
  // Sorted for deterministic, reproducible ordering across addons.
  const manifests = globSync('**/*.weave.mjs', { cwd: frontendRoot }).sort()

  const modules = await Promise.all(
    manifests.map(
      (relativePath) => import(pathToFileURL(resolve(frontendRoot, relativePath)).href),
    ),
  )

  return modules.flatMap((module, i) => {
    const rules = module.addonWeaveRules ?? module.default
    if (rules === undefined) return []
    if (!Array.isArray(rules)) {
      throw new Error(`[addon-weave] ${manifests[i]}: default export is not an array.`)
    }
    // Stamp each rule with the manifest it came from — a repo-relative path so
    // plugin.mjs can point a failure straight at the addon file to fix (openable
    // as-is), not just the core SFC the rule failed to weave into.
    for (const rule of rules) rule.manifest = `app/frontend/${manifests[i]}`
    return rules
  })
}
