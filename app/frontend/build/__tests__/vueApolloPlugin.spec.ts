// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'fs'
import { createRequire } from 'node:module'
import { tmpdir } from 'os'
import { join, resolve } from 'path'

import { afterEach, describe, expect, it } from 'vitest'

// The plugins resolve the CJS build of graphql; building the schema from the
// ESM import would fail its cross-realm instanceOf checks.
/* eslint-disable @typescript-eslint/no-require-imports */
const stockPlugin = require('@graphql-codegen/typescript-vue-apollo')
const { buildSchema, parse } = require('graphql')

const dispatcher = require('../vueApolloPlugin.js')
const { vueApolloV5Documents } = require('../vueApolloV5Documents.js')
/* eslint-enable @typescript-eslint/no-require-imports */

const schema = buildSchema(`
  type Query {
    users: [User!]!
  }

  type User {
    id: ID!
  }
`)

// Mirrors the repository codegen config for the './app/frontend/' entry.
const config = {
  importOperationTypesFrom: 'Types',
  addDocBlocks: false,
}

const documentsFor = (location: string) => [
  { location, document: parse('query users { users { id } }') },
]

// Fictitious paths: the dispatcher only checks the set, and the real
// allowlist entries stay untouched for the rest of the worker.
const allowlistedPath = 'app/frontend/shared/graphql/queries/allowlisted.graphql'
const notAllowlistedPath = 'app/frontend/shared/graphql/queries/notAllowlisted.graphql'

const toOutput = (result: { prepend: string[]; content: string }) =>
  [...result.prepend, result.content].join('\n')

describe('vueApolloPlugin', () => {
  afterEach(() => {
    vueApolloV5Documents.delete(allowlistedPath)
  })

  it('routes an allowlisted document to the v5 plugin, normalising an absolute location', () => {
    vueApolloV5Documents.add(allowlistedPath)

    const output = toOutput(
      dispatcher.plugin(schema, documentsFor(resolve(allowlistedPath)), config),
    )

    expect(output).toContain("import * as VueApolloComposable from '@vue/apollo-composable';")
    expect(output).toContain('VueApolloComposable.useQuery.Options')
    expect(output).not.toContain('@vue/apollo-composable/compat')
  })

  it('produces output identical to the stock compat setup for any other document', () => {
    vueApolloV5Documents.add(allowlistedPath)

    const location = resolve(notAllowlistedPath)

    // The reference output is what the former `.graphql_code_generator.js`
    // produced: the stock plugin with the compat import source.
    const reference = stockPlugin.plugin(schema, documentsFor(location), {
      ...config,
      vueApolloComposableImportFrom: '@vue/apollo-composable/compat',
      vueCompositionApiImportFrom: 'vue',
    })

    expect(dispatcher.plugin(schema, documentsFor(location), config)).toEqual(reference)
  })

  it('aborts at module load when the allowlist names a file that does not exist', () => {
    const source = readFileSync(resolve(__dirname, '../vueApolloV5Documents.js'), 'utf8')
    const missingPath = 'app/frontend/shared/graphql/queries/doesNotExist.graphql'
    const patched = source.replace(
      /const vueApolloV5Documents = new Set\(\[[^\]]*\]\)/,
      `const vueApolloV5Documents = new Set(['${missingPath}'])`,
    )
    expect(patched).not.toBe(source)

    const dir = mkdtempSync(join(tmpdir(), 'vue-apollo-v5-documents-'))
    const moduleFile = join(dir, 'vueApolloV5Documents.js')
    writeFileSync(moduleFile, patched)

    // Native require: the temp module lives outside the Vite roots.
    const nativeRequire = createRequire(__filename)

    try {
      expect(() => nativeRequire(moduleFile)).toThrowError(missingPath)
    } finally {
      rmSync(dir, { recursive: true, force: true })
    }
  })
})
