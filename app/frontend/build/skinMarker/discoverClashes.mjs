// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * Build-time discovery of ambiguous skin-marker names.
 *
 * Globs every SFC under `app/frontend` and returns the set of file names used by
 * more than one component that can render in the same app (see findAmbiguousNames).
 * plugin.mjs qualifies exactly those names (e.g. `UserTaskbarTabs/Organization`)
 * and leaves every other marker as the plain component name.
 */

import { globSync } from 'node:fs'
import { resolve } from 'node:path'

import { findAmbiguousNames } from './plugin.mjs'

// Anchor on the project root (Vite/Vitest run from it); see addonWeave/discoverRules.mjs.
const frontendRoot = resolve(process.cwd(), 'app/frontend')

// Directories whose SFCs never ship in an app bundle, so they can't cause a
// runtime clash: unit tests, mocks, and test-support components (app/frontend/tests/).
const NON_BUNDLE_DIRS = new Set(['__tests__', 'tests', 'mocks'])

export const discoverSkinMarkerClashes = () => {
  const files = globSync('**/*.vue', { cwd: frontendRoot }).filter(
    (file) => !file.split('/').some((segment) => NON_BUNDLE_DIRS.has(segment)),
  )
  return findAmbiguousNames(files)
}
