// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable no-nested-ternary */

const { basename } = require('path')

const { convertFactory } = require('@graphql-codegen/visitor-plugin-common')
const camelCase = require('lodash/camelCase.js')
const startCase = require('lodash/startCase.js')

/** @typedef {import('graphql').OperationDefinitionNode} OperationDefinitionNode */

const pascalCase = (str) => startCase(camelCase(str))

const getCompositionFunctionSuffix = (name, operationType) => {
  if (
    name.includes('Query') ||
    name.includes('Mutation') ||
    name.includes('Subscription')
  ) {
    return ''
  }
  return pascalCase(operationType)
}

const getOperationSuffix = (config, node, operationType) => {
  const { omitOperationSuffix = false, dedupeOperationSuffix = false } = config
  const operationName =
    typeof node === 'string' ? node : node.name ? node.name.value : ''
  return omitOperationSuffix
    ? ''
    : dedupeOperationSuffix &&
        operationName.toLowerCase().endsWith(operationType.toLowerCase())
      ? ''
      : operationType
}

module.exports.plugin = (schema, documents, config) => {
  // we assume that there is only one operation per file
  // if not, then we take the first operation and assume it is the only one
  const node = documents[0].document.definitions[0]

  const suffix = getCompositionFunctionSuffix(node.name.value, node.operation)
  const convertName = convertFactory(config)
  const operationName = convertName(node.name.value, {
    suffix,
    useTypesPrefix: false,
  })
  const baseFile = basename(documents[0].location).replace(
    /\.graphql$/,
    '.api.ts',
  )

  const documentVariableName = convertName(node, {
    suffix: config.documentVariableSuffix || 'Document',
    prefix: config.documentVariablePrefix,
    useTypesPrefix: false,
  })
  const operationType = pascalCase(node.operation)
  const operationTypeSuffix = getOperationSuffix(config, node, operationType)
  const operationResultType = `Types.${convertName(node, {
    suffix: operationTypeSuffix,
  })}`
  const operationVariablesTypes = `Types.${convertName(node, {
    suffix: `${operationTypeSuffix}Variables`,
  })}`

  return {
    prepend: [
      "import * as Mocks from '#tests/graphql/builders/mocks.ts'",
      `import * as Operations from './${baseFile}'`,
    ],
    content: [
      node.operation === 'subscription'
        ? `
export function get${operationName}Handler() {
  return Mocks.getGraphQLSubscriptionHandler<${operationResultType}>(Operations.${documentVariableName})
}
`
        : `
export function mock${operationName}(defaults: Mocks.MockDefaultsValue<${operationResultType}, ${operationVariablesTypes}>) {
  return Mocks.mockGraphQLResult(Operations.${documentVariableName}, defaults)
}

export function waitFor${operationName}Calls() {
  return Mocks.waitForGraphQLMockCalls<${operationResultType}>(Operations.${documentVariableName})
}
`,
    ],
  }
}
