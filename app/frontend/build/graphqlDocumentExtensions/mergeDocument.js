// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * Pure AST merge of a base GraphQL document with parsed `.extensions/*.graphql`
 * documents (no filesystem access — see transform.js for the disk-reading
 * codegen document transform that calls this).
 *
 * @typedef {import('graphql').DocumentNode} DocumentNode
 * @typedef {import('graphql').GraphQLSchema} GraphQLSchema
 * @typedef {{ fileName: string, document: DocumentNode }} ExtensionDoc
 */

const { Kind, TypeInfo, visit, visitWithTypeInfo, isAbstractType, print } = require('graphql')

// Every violation names the offending extension file, so a broken addon fails
// the build with an actionable message instead of an opaque codegen error.
const failure = (source, message) =>
  new Error(`[graphql-document-extensions] ${source}: ${message}`)

// Root selections are Fields; the merged-set key is the alias if present,
// otherwise the field name — the same identity GraphQL itself uses.
const rootSelectionKey = (selection, source) => {
  if (selection.kind !== Kind.FIELD) {
    throw failure(
      source,
      `root selections in a mergeable operation must be fields (got '${selection.kind}').`,
    )
  }
  return selection.alias?.value ?? selection.name.value
}

// Every SelectionSet node (by identity) whose parent type is a union/interface
// counting `fragmentType` among its possible types. Object parent types never
// match, so a fragment lands once per abstract position and never additionally
// inside a nested `... on X` block of the same type.
const findAcceptingSelectionSets = (document, schema, fragmentType) => {
  const typeInfo = new TypeInfo(schema)
  const matches = new Set()

  visit(
    document,
    visitWithTypeInfo(typeInfo, {
      SelectionSet(node) {
        const parentType = typeInfo.getParentType()
        if (
          parentType &&
          isAbstractType(parentType) &&
          schema.isSubType(parentType, fragmentType)
        ) {
          matches.add(node)
        }
      },
    }),
  )

  return matches
}

const insertSpreadInto = (document, matches, fragmentName) =>
  visit(document, {
    SelectionSet(node) {
      if (!matches.has(node)) return undefined

      return {
        ...node,
        selections: [
          ...node.selections,
          {
            kind: Kind.FRAGMENT_SPREAD,
            name: { kind: Kind.NAME, value: fragmentName },
            // Optional per the AST types, but codegen plugins have read it
            // without a nullish check before ('spread.directives is not
            // iterable') — keep the synthesized node complete.
            directives: [],
          },
        ],
      }
    },
  })

// Append an extension operation's root selections + variables to the base
// operation; its own name is discarded. `usedRootKeys`/`usedVariables` are
// threaded across all extension files, so duplicates are caught globally.
const mergeOperationRoot = (baseOperation, extOperation, usedRootKeys, usedVariables, fileName) => {
  if (extOperation.operation !== baseOperation.operation) {
    throw failure(
      fileName,
      `operation type '${extOperation.operation}' does not match the base document's '${baseOperation.operation}' operation.`,
    )
  }

  const addedSelections = extOperation.selectionSet.selections.map((selection) => {
    const key = rootSelectionKey(selection, fileName)
    if (usedRootKeys.has(key)) {
      throw failure(
        fileName,
        `duplicate root field '${key}' — already defined by the base document or an earlier extension file.`,
      )
    }
    usedRootKeys.add(key)
    return selection
  })

  // Base (or an earlier extension) wins on a variable-name conflict, but only
  // if the types agree — a same-named variable of a different type is a
  // mistake, caught here instead of as an unattributed validation error later.
  // Differing default values are fine either way.
  const addedVariables = (extOperation.variableDefinitions ?? []).filter((variable) => {
    const name = variable.variable.name.value
    const existing = usedVariables.get(name)

    if (existing) {
      if (print(existing.type) !== print(variable.type)) {
        throw failure(
          fileName,
          `variable '$${name}' type mismatch — expected '${print(existing.type)}' (from the base document or an earlier extension file), got '${print(variable.type)}'.`,
        )
      }
      return false
    }

    usedVariables.set(name, variable)
    return true
  })

  return {
    ...baseOperation,
    selectionSet: {
      ...baseOperation.selectionSet,
      selections: [...baseOperation.selectionSet.selections, ...addedSelections],
    },
    variableDefinitions: [...(baseOperation.variableDefinitions ?? []), ...addedVariables],
  }
}

// Append a fragment definition and spread it into every accepting selection set.
const mergeFragment = (document, fragment, { schema, usedFragmentNames, fileName, location }) => {
  const fragmentName = fragment.name.value
  if (usedFragmentNames.has(fragmentName)) {
    throw failure(fileName, `duplicate fragment name '${fragmentName}'.`)
  }
  usedFragmentNames.add(fragmentName)

  const typeConditionName = fragment.typeCondition.name.value
  const fragmentType = schema.getType(typeConditionName)
  if (!fragmentType) {
    throw failure(
      fileName,
      `fragment '${fragmentName}' targets unknown schema type '${typeConditionName}'.`,
    )
  }

  const matches = findAcceptingSelectionSets(document, schema, fragmentType)
  if (matches.size === 0) {
    throw failure(
      fileName,
      `fragment '${fragmentName}' on '${typeConditionName}' matches no union or interface selection set in ${location} — dead extension.`,
    )
  }

  const withSpreads = insertSpreadInto(document, matches, fragmentName)

  return { ...withSpreads, definitions: [...withSpreads.definitions, fragment] }
}

/**
 * Merge `extensionDocs` (pre-parsed, already sorted by filename) into
 * `document`. Returns `document` unchanged when there is nothing to merge.
 * Throws — naming the offending extension file — on any convention violation.
 *
 * @param {{ document: DocumentNode, location: string, extensionDocs: ExtensionDoc[], schema: GraphQLSchema }} args
 * @returns {DocumentNode}
 */
const mergeDocumentExtensions = ({ document, location, extensionDocs, schema }) => {
  if (extensionDocs.length === 0) return document

  const baseOperationIndex = document.definitions.findIndex(
    (definition) => definition.kind === Kind.OPERATION_DEFINITION,
  )
  const baseOperation =
    baseOperationIndex === -1 ? undefined : document.definitions[baseOperationIndex]

  const usedRootKeys = new Set(
    (baseOperation?.selectionSet.selections ?? []).map((selection) =>
      rootSelectionKey(selection, location),
    ),
  )
  // Variable name -> the definition currently holding that name, so a later
  // same-named variable can be checked for a type conflict.
  const usedVariables = new Map(
    (baseOperation?.variableDefinitions ?? []).map((variable) => [
      variable.variable.name.value,
      variable,
    ]),
  )
  const usedFragmentNames = new Set(
    document.definitions
      .filter((definition) => definition.kind === Kind.FRAGMENT_DEFINITION)
      .map((definition) => definition.name.value),
  )

  // Own copy of the document, so the base operation can be replaced in place as
  // extension files are applied — the input document is never mutated.
  let working = { ...document, definitions: [...document.definitions] }

  for (const { fileName, document: extensionDocument } of extensionDocs) {
    for (const definition of extensionDocument.definitions) {
      if (definition.kind === Kind.OPERATION_DEFINITION) {
        if (baseOperationIndex === -1) {
          throw failure(fileName, `extends an operation, but ${location} defines none.`)
        }

        working.definitions[baseOperationIndex] = mergeOperationRoot(
          working.definitions[baseOperationIndex],
          definition,
          usedRootKeys,
          usedVariables,
          fileName,
        )
        continue
      }

      if (definition.kind === Kind.FRAGMENT_DEFINITION) {
        working = mergeFragment(working, definition, {
          schema,
          usedFragmentNames,
          fileName,
          location,
        })
        continue
      }

      throw failure(
        fileName,
        `unsupported definition kind '${definition.kind}' — extension files may only contain operations or fragments.`,
      )
    }
  }

  return working
}

module.exports = { mergeDocumentExtensions }
