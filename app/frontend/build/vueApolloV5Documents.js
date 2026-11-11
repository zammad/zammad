// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Allowlist of .graphql documents whose generated composables use the native
// @vue/apollo-composable v5 shape; every document not listed keeps the compat
// (v4 three-argument) shape until its call sites are migrated.
//
// Policy: a document added while this allowlist exists goes on it from the
// start. Fragment-only documents never go on it — both generators emit
// identical bytes for them.

const fs = require('fs')
const path = require('path')

// Repo-relative POSIX paths, one per line.
const vueApolloV5Documents = new Set([
  'app/frontend/shared/graphql/queries/about.graphql',
  'app/frontend/shared/graphql/queries/applicationConfig.graphql',
  'app/frontend/shared/graphql/queries/locales.graphql',
  'app/frontend/shared/graphql/queries/translations.graphql',
])

const toRepoRelativePath = (location) =>
  path.relative(process.cwd(), path.resolve(location)).split(path.sep).join('/')

// A typo here must abort codegen instead of silently leaving the document on compat.
vueApolloV5Documents.forEach((documentPath) => {
  if (!fs.existsSync(path.resolve(documentPath))) {
    throw new Error(`vueApolloV5Documents lists a file that does not exist: ${documentPath}`)
  }
})

const isVueApolloV5Document = (location) => vueApolloV5Documents.has(toRepoRelativePath(location))

module.exports = { isVueApolloV5Document, vueApolloV5Documents }
