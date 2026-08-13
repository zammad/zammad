// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * Proves `documentTransforms` actually propagates through
 * `@graphql-codegen/near-operation-file-preset` — the preset receives
 * `documentTransforms` as part of its options and must forward it into each
 * generated section for `@graphql-codegen/core` to apply. If a future preset
 * upgrade stops doing that, this test fails loudly instead of the merge
 * silently vanishing from real `.api.ts` output.
 */

import { readFileSync } from 'fs'
import { resolve } from 'path'

import { executeCodegen } from '@graphql-codegen/cli'
import { describe, expect, it } from 'vitest'

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { graphqlDocumentExtensionsTransform } = require('../transform.js')

const fixturesDir = resolve(__dirname, 'fixtures')
const schemaSdl = readFileSync(resolve(fixturesDir, 'testSchema.graphql'), 'utf8')

// Runs the real codegen pipeline over one fixture's base document. `plugins`
// mirrors the plugins the repo config uses, since a merged document has to
// survive all of them.
const generate = async (fixture: string, plugins: string[]) => {
  const baseDocumentPath = resolve(fixturesDir, fixture, 'base.graphql')

  const { result, error } = await executeCodegen({
    schema: schemaSdl,
    documents: [baseDocumentPath],
    generates: {
      [resolve(fixturesDir, fixture) + '/']: {
        documents: [baseDocumentPath],
        preset: 'near-operation-file',
        presetConfig: {
          baseTypesPath: 'types.ts',
          importTypesNamespace: 'Types',
          extension: '.api.ts',
        },
        plugins,
        documentTransforms: [graphqlDocumentExtensionsTransform],
      },
    },
  })

  expect(error).toBeNull()
  expect(result).toHaveLength(1)

  return result[0].content
}

describe('documentTransforms propagation through near-operation-file preset', () => {
  it('includes the extension-merged fields in the generated output', async () => {
    const content = await generate('operationMerge', ['typescript-operations'])

    // Present only if the extensions' root fields survived the preset's
    // per-file document rebuild and reached the plugin.
    expect(content).toContain('searchAddonA')
    expect(content).toContain('searchAddonB')
    expect(content).toContain('offset')
  })

  // A merged fragment takes a different path through the plugins than merged
  // root fields (the spread is a node we synthesize, not one copied from a
  // parsed document), so it is generated through the plugins the repo config
  // uses for its document outputs.
  it('generates output for a merged fragment through operations and vue-apollo plugins', async () => {
    const content = await generate('fragmentMerge', [
      'typescript-operations',
      'typescript-vue-apollo',
    ])

    expect(content).toContain('userDetailSearch')
    expect(content).toContain('...userDetailSearch')
  })
})
