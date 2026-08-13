// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'fs'
import { tmpdir } from 'os'
import { join, resolve } from 'path'

import { parse, print } from 'graphql'
import { describe, expect, it } from 'vitest'

import type { DocumentNode } from 'graphql'

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { graphqlDocumentExtensionsTransform } = require('../transform.js')

const fixturesDir = resolve(__dirname, 'fixtures')

const schemaAst = parse(readFileSync(resolve(fixturesDir, 'testSchema.graphql'), 'utf8'))

// Builds the single-entry `documents` array graphql-codegen would pass in for
// one base document, with `location` pointing at the real fixture file so the
// transform's sibling `.extensions/` disk lookup runs for real.
const documentFor = (fixture: string) => {
  const location = resolve(fixturesDir, fixture, 'base.graphql')
  return { location, document: parse(readFileSync(location, 'utf8')) }
}

const transformFixture = (fixture: string) =>
  graphqlDocumentExtensionsTransform.transform({
    documents: [documentFor(fixture)],
    schema: schemaAst,
  })

describe('graphqlDocumentExtensionsTransform', () => {
  it('passes a document without an .extensions directory through unchanged', () => {
    const original = documentFor('noExtensions')
    const result = graphqlDocumentExtensionsTransform.transform({
      documents: [original],
      schema: schemaAst,
    })

    expect(result[0]).toBe(original)
    expect(result[0].document).toBe(original.document)
  })

  it('appends extension root selections in filename order and dedupes variables (base wins)', () => {
    const [{ document }] = transformFixture('operationMerge')
    const operation = document.definitions[0] as any

    expect(operation.selectionSet.selections.map((s: any) => (s.alias ?? s.name).value)).toEqual([
      'search',
      'searchAddonA',
      'searchAddonB',
    ])

    // Extension operation names are discarded — only one operation remains.
    expect(document.definitions).toHaveLength(1)
    expect(operation.name.value).toBe('search')

    const variableNames = operation.variableDefinitions.map((v: any) => v.variable.name.value)
    expect(variableNames).toEqual(['search', 'limit', 'offset'])

    // Base's `$limit` (no default) wins over the extension's `$limit: Int = 99`.
    const limitVar = operation.variableDefinitions.find(
      (v: any) => v.variable.name.value === 'limit',
    )
    expect(limitVar.defaultValue).toBeUndefined()
  })

  it('appends a fragment and spreads it into the union-typed selection set', () => {
    const [{ document }] = transformFixture('fragmentMerge')

    expect(document.definitions).toHaveLength(2)
    const fragment = document.definitions.find((d: any) => d.kind === 'FragmentDefinition') as any
    expect(fragment.name.value).toBe('userDetailSearch')
    expect(fragment.typeCondition.name.value).toBe('User')

    const printed = print(document)
    expect(printed).toContain('...userDetailSearch')
    expect(printed).toContain('fragment userDetailSearch on User')
  })

  it('is deterministic across multiple extension files (filename order)', () => {
    const [{ document: first }] = transformFixture('operationMerge')
    const [{ document: second }] = transformFixture('operationMerge')

    expect(print(first)).toBe(print(second))
  })

  it('throws naming the file on a duplicate root field alias across extensions', () => {
    expect(() => transformFixture('duplicateRootField')).toThrow(/02-addon\.graphql/)
    expect(() => transformFixture('duplicateRootField')).toThrow(/addonField/)
  })

  it('throws naming the file on a duplicate fragment name', () => {
    expect(() => transformFixture('duplicateFragmentName')).toThrow(/02-addon\.graphql/)
    expect(() => transformFixture('duplicateFragmentName')).toThrow(/userDetailSearch/)
  })

  it('throws naming the file when a fragment matches no selection set', () => {
    expect(() => transformFixture('deadFragment')).toThrow(/addon\.graphql/)
    expect(() => transformFixture('deadFragment')).toThrow(/organizationDetailSearch/)
  })

  it('throws naming the file on an unsupported definition kind', () => {
    expect(() => transformFixture('unsupportedDefinition')).toThrow(/addon\.graphql/)
    expect(() => transformFixture('unsupportedDefinition')).toThrow(/unsupported definition kind/)
  })

  it('throws when an extension root field collides with the BASE document itself', () => {
    expect(() => transformFixture('duplicateRootFieldVsBase')).toThrow(/01-addon\.graphql/)
    expect(() => transformFixture('duplicateRootFieldVsBase')).toThrow(/search/)
  })

  it('throws when an extension operation extends a base document with no operation', () => {
    expect(() => transformFixture('operationOnNoOperationBase')).toThrow(/addon\.graphql/)
    expect(() => transformFixture('operationOnNoOperationBase')).toThrow(/defines none/)
  })

  it('throws on a same-named variable with a conflicting type', () => {
    expect(() => transformFixture('variableTypeConflict')).toThrow(/addon\.graphql/)
    expect(() => transformFixture('variableTypeConflict')).toThrow(
      /'\$limit' type mismatch.*'Int'.*'String'/s,
    )
  })

  it('throws when an extension operation type does not match the base operation type', () => {
    expect(() => transformFixture('operationTypeMismatch')).toThrow(/addon\.graphql/)
    expect(() => transformFixture('operationTypeMismatch')).toThrow(
      /'mutation'.*does not match.*'query'/s,
    )
  })

  // AST-based (not printed-string regex) so nesting depth is unambiguous.
  const namedField = (selectionSet: any, name: string) =>
    selectionSet.selections.find(
      (s: any) => s.kind === 'Field' && (s.alias?.value ?? s.name.value) === name,
    )
  const fragmentSpreadNames = (selectionSet: any) =>
    selectionSet.selections
      .filter((s: any) => s.kind === 'FragmentSpread')
      .map((s: any) => s.name.value)
  const namedFragment = (document: DocumentNode, name: string) =>
    document.definitions.find(
      (d: any) => d.kind === 'FragmentDefinition' && d.name.value === name,
    ) as any

  it('spreads a fragment into the union selection set only, not a nested inline fragment', () => {
    const [{ document }] = transformFixture('fragmentPruneNesting')
    const operation = document.definitions[0] as any
    const itemsSelectionSet = namedField(
      namedField(operation.selectionSet, 'search').selectionSet,
      'items',
    ).selectionSet

    expect(fragmentSpreadNames(itemsSelectionSet)).toEqual(['userDetailSearch'])

    // NOT also spread into the nested `... on User { id }` inline fragment.
    const onUser = itemsSelectionSet.selections.find(
      (s: any) => s.kind === 'InlineFragment' && s.typeCondition.name.value === 'User',
    )
    expect(fragmentSpreadNames(onUser.selectionSet)).toEqual([])
  })

  it("does not spread a later fragment into an earlier fragment's own body", () => {
    const [{ document }] = transformFixture('fragmentPruneAcrossFragments')
    const operation = document.definitions[0] as any
    const itemsSelectionSet = namedField(
      namedField(operation.selectionSet, 'search').selectionSet,
      'items',
    ).selectionSet

    expect(fragmentSpreadNames(itemsSelectionSet)).toEqual(['userBasic', 'userExtra'])
    expect(fragmentSpreadNames(namedFragment(document, 'userBasic').selectionSet)).toEqual([])
    expect(fragmentSpreadNames(namedFragment(document, 'userExtra').selectionSet)).toEqual([])
  })

  it('throws a clear error on a non-Field root selection instead of a bare TypeError', () => {
    expect(() => transformFixture('nonFieldRootSelection')).toThrow(/addon\.graphql/)
    expect(() => transformFixture('nonFieldRootSelection')).toThrow(
      /root selections .* must be fields/,
    )
  })

  it('extends a fragment-only base document (shared-fragment case, e.g. taskbar attributes)', () => {
    const [{ document }] = transformFixture('fragmentDocumentBase')

    expect(document.definitions).toHaveLength(2)

    const baseFragment = document.definitions.find(
      (d: any) => d.name.value === 'resultAttributes',
    ) as any
    const itemsField = baseFragment.selectionSet.selections.find(
      (s: any) => s.name?.value === 'items',
    )
    const spreadsIn = (selections: any[]) =>
      selections.filter((s: any) => s.kind === 'FragmentSpread').map((s: any) => s.name.value)

    // Spread lands in the union-typed `items` set, not the fragment's own body.
    expect(spreadsIn(itemsField.selectionSet.selections)).toEqual(['userEntityAttributes'])
    expect(spreadsIn(baseFragment.selectionSet.selections)).toEqual([])
  })

  it('names the extension file in a GraphQL syntax error', () => {
    // The extension-file path lives on `error.source.name` (and in the
    // formatted `toString()` output) — plain `.message` never carries it,
    // which is exactly the gap `parse(new Source(...))` closes.
    // Built at runtime: an intentionally invalid .graphql file cannot live in
    // the repo, the pre-commit code-style check parses every .graphql file.
    const dir = mkdtempSync(join(tmpdir(), 'graphql-document-extensions-'))
    try {
      const baseSource = 'query search($search: String!) { search(search: $search) { totalCount } }'
      const location = join(dir, 'base.graphql')
      writeFileSync(location, baseSource)
      mkdirSync(join(dir, 'base.extensions'))
      writeFileSync(
        join(dir, 'base.extensions', 'addon.graphql'),
        'query broken($search: String!) {\n  addonField: search(search:\n}\n',
      )

      expect.assertions(1)
      try {
        graphqlDocumentExtensionsTransform.transform({
          documents: [{ location, document: parse(baseSource) }],
          schema: schemaAst,
        })
      } catch (error) {
        expect((error as { source?: { name?: string } }).source?.name).toContain(
          'base.extensions/addon.graphql',
        )
      }
    } finally {
      rmSync(dir, { recursive: true, force: true })
    }
  })

  it('leaves documents without a location untouched', () => {
    const inlineOnly = { document: parse('query q { __typename }') as DocumentNode }
    const result = graphqlDocumentExtensionsTransform.transform({
      documents: [inlineOnly],
      schema: schemaAst,
    })
    expect(result[0]).toBe(inlineOnly)
  })
})
