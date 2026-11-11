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
import { relative, resolve, sep } from 'path'

import { executeCodegen } from '@graphql-codegen/cli'
import { describe, expect, it } from 'vitest'

/* eslint-disable @typescript-eslint/no-require-imports */
const vueApolloPluginModule = require('../../vueApolloPlugin.js')
const { vueApolloV5Documents } = require('../../vueApolloV5Documents.js')
const { graphqlDocumentExtensionsTransform } = require('../transform.js')
/* eslint-enable @typescript-eslint/no-require-imports */

const fixturesDir = resolve(__dirname, 'fixtures')
const schemaSdl = readFileSync(resolve(fixturesDir, 'testSchema.graphql'), 'utf8')

// Hands codegen the dispatcher instance this spec mutates the allowlist of —
// the default loader's require would load a second, unmutated copy.
const vueApolloPluginLoader = async (name: string) => {
  if (name.endsWith('vueApolloPlugin.js')) return vueApolloPluginModule

  throw Object.assign(new Error(`Unexpected module: ${name}`), { code: 'MODULE_NOT_FOUND' })
}

// Runs the real codegen pipeline over one fixture's base document. `plugins`
// mirrors the plugins the repo config uses, since a merged document has to
// survive all of them.
const generate = async (
  fixture: string,
  plugins: string[],
  pluginLoader?: typeof vueApolloPluginLoader,
) => {
  const baseDocumentPath = resolve(fixturesDir, fixture, 'base.graphql')

  const { result, error } = await executeCodegen({
    schema: schemaSdl,
    documents: [baseDocumentPath],
    ...(pluginLoader ? { pluginLoader } : {}),
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

  // The dispatcher is given with a path relative to the working directory, as
  // the repository config does.
  it('keeps the merged fragment when the dispatcher routes an allowlisted document to the v5 visitor', async () => {
    const baseDocumentPath = resolve(fixturesDir, 'fragmentMerge', 'base.graphql')
    const allowlistedPath = relative(process.cwd(), baseDocumentPath).split(sep).join('/')
    vueApolloV5Documents.add(allowlistedPath)

    try {
      const content = await generate(
        'fragmentMerge',
        ['./app/frontend/build/vueApolloPlugin.js'],
        vueApolloPluginLoader,
      )

      expect(content).toContain("import * as VueApolloComposable from '@vue/apollo-composable';")
      expect(content).toContain('VueApolloComposable.useQuery.Options')
      expect(content).toContain('...userDetailSearch')
    } finally {
      vueApolloV5Documents.delete(allowlistedPath)
    }
  })
})
