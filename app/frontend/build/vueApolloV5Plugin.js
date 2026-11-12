// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// GraphQL Code Generator plugin emitting the native @vue/apollo-composable v5
// shape. The stock typescript-vue-apollo plugin still generates the v4
// three-argument API (useQuery(doc, variables, options)); v5 moved variables
// into a single options argument, replaced UseXOptions/UseXReturn with the
// namespaced useX.Options/useX.Result types, and needs neither the
// VueCompositionApi import nor the ReactiveFunction type.

const { extname } = require('path')

const { oldVisit } = require('@graphql-codegen/plugin-helpers')
const { VueApolloVisitor } = require('@graphql-codegen/typescript-vue-apollo')
const { concatAST, Kind } = require('graphql')

class VueApolloV5Visitor extends VueApolloVisitor {
  get vueCompositionApiImport() {
    return ''
  }

  get reactiveFunctionType() {
    return ''
  }

  buildCompositionFunction({
    operationName,
    operationType,
    operationResultType,
    operationVariablesTypes,
    operationHasNonNullableVariable,
    documentNodeVariable,
  }) {
    // Spreading undefined options is a no-op, so the merge also covers the
    // optional lazy query options.
    const passOptions = this.config.clientId
      ? `{ clientId: '${this.config.clientId}', ...options }`
      : 'options'

    switch (operationType) {
      case 'Query': {
        const optionsParam = operationHasNonNullableVariable
          ? `options: VueApolloComposable.useQuery.Options<${operationResultType}, ${operationVariablesTypes}>`
          : `options: VueApolloComposable.useQuery.Options<${operationResultType}, ${operationVariablesTypes}> = {}`
        return `export function use${operationName}(${optionsParam}) {
  return VueApolloComposable.useQuery<${operationResultType}, ${operationVariablesTypes}>(${documentNodeVariable}, ${passOptions});
}`
      }
      case 'LazyQuery': {
        // Required variables may still arrive via load(), so the options stay optional.
        const optionsParam = `options?: VueApolloComposable.useLazyQuery.Options<${operationResultType}, ${operationVariablesTypes}>`
        return `export function use${operationName}(${optionsParam}) {
  return VueApolloComposable.useLazyQuery<${operationResultType}, ${operationVariablesTypes}>(${documentNodeVariable}, ${passOptions});
}`
      }
      case 'Mutation': {
        // Mutation variables are passed to mutate() later, never at hook level.
        const optionsParam = `options: VueApolloComposable.useMutation.Options<${operationResultType}, ${operationVariablesTypes}> = {}`
        return `export function use${operationName}(${optionsParam}) {
  return VueApolloComposable.useMutation<${operationResultType}, ${operationVariablesTypes}>(${documentNodeVariable}, ${passOptions});
}`
      }
      case 'Subscription': {
        const optionsParam = operationHasNonNullableVariable
          ? `options: VueApolloComposable.useSubscription.Options<${operationResultType}, ${operationVariablesTypes}>`
          : `options: VueApolloComposable.useSubscription.Options<${operationResultType}, ${operationVariablesTypes}> = {}`
        return `export function use${operationName}(${optionsParam}) {
  return VueApolloComposable.useSubscription<${operationResultType}, ${operationVariablesTypes}>(${documentNodeVariable}, ${passOptions});
}`
      }
    }
  }

  buildCompositionFunctionReturnType({
    operationName,
    operationType,
    operationResultType,
    operationVariablesTypes,
  }) {
    const composableMap = {
      Query: 'useQuery',
      Mutation: 'useMutation',
      Subscription: 'useSubscription',
    }
    const composableName = composableMap[operationType] ?? 'useQuery'
    return `export type ${operationName}CompositionFunctionResult = VueApolloComposable.${composableName}.Result<${operationResultType}, ${operationVariablesTypes}>;`
  }
}

/** @type {import('@graphql-codegen/plugin-helpers').PluginFunction} */
const plugin = (schema, documents, config) => {
  const allAst = concatAST(documents.map((s) => s.document))
  const allFragments = [
    ...allAst.definitions
      .filter((d) => d.kind === Kind.FRAGMENT_DEFINITION)
      .map((fragmentDef) => ({
        node: fragmentDef,
        name: fragmentDef.name.value,
        onType: fragmentDef.typeCondition.name.value,
        isExternal: false,
      })),
    ...(config.externalFragments || []),
  ]

  const visitor = new VueApolloV5Visitor(schema, allFragments, config, documents)
  const visitorResult = oldVisit(allAst, { leave: visitor })

  return {
    // The overridden composition API import and ReactiveFunction type arrive
    // as empty strings — drop them instead of emitting blank lines.
    prepend: visitor.getImports().filter(Boolean),
    content: [
      visitor.fragments,
      ...visitorResult.definitions.filter((definition) => typeof definition === 'string'),
    ].join('\n'),
  }
}

const validate = async (_schema, _documents, _config, { outputFile }) => {
  if (extname(outputFile) !== '.ts' && extname(outputFile) !== '.tsx') {
    throw new Error(`Plugin "vue-apollo-v5" requires extension to be ".ts" or ".tsx"!`)
  }
}

module.exports = { plugin, validate }
