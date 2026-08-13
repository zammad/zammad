// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * graphql-codegen document transform that lets an addon extend a core
 * `.graphql` document by dropping `.graphql` files into a sibling
 * `<basename>.extensions/` directory — no core document is ever edited. Since
 * this runs at codegen time, the merged operation/types flow into the normal
 * generated `.api.ts` / `types.ts` / `.mocks.ts` artifacts. See ./README.md.
 */

const fs = require('fs')
const path = require('path')

const { buildASTSchema, parse, print, Source } = require('graphql')

const { mergeDocumentExtensions } = require('./mergeDocument.js')

const extensionsDirFor = (location) =>
  path.join(path.dirname(location), `${path.basename(location, '.graphql')}.extensions`)

/** Sibling `.graphql` files for `location`, parsed and sorted by filename for deterministic merging. */
const readExtensionDocuments = (location) => {
  const dir = extensionsDirFor(location)
  if (!fs.existsSync(dir)) return []

  return fs
    .readdirSync(dir)
    .filter((fileName) => fileName.endsWith('.graphql'))
    .sort()
    .map((fileName) => {
      const filePath = path.join(dir, fileName)
      // Wrapping in a `Source` names the file in a `GraphQLSyntaxError` — a
      // bare `parse(text)` would only report a line/column, not which
      // extension file it came from.
      return { fileName, document: parse(new Source(fs.readFileSync(filePath, 'utf8'), filePath)) }
    })
}

// The schema is only needed for type-driven fragment placement, and only ever
// requested once — build it lazily so documents with no extensions cost
// nothing extra.
const graphqlDocumentExtensionsTransform = {
  transform: ({ documents, schema: schemaAst }) => {
    let schema

    return documents.map((file) => {
      if (!file.location) return file

      const extensionDocs = readExtensionDocuments(file.location)
      if (extensionDocs.length === 0) return file

      schema ??= buildASTSchema(schemaAst)
      const document = mergeDocumentExtensions({
        document: file.document,
        location: file.location,
        extensionDocs,
        schema,
      })

      return { ...file, document, rawSDL: print(document) }
    })
  },
}

module.exports = { graphqlDocumentExtensionsTransform }
