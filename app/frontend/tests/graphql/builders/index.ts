// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable no-restricted-syntax */
/* eslint-disable no-use-before-define */

import { faker } from '@faker-js/faker'
import {
  convertToGraphQLId,
  getIdFromGraphQLId,
} from '#shared/graphql/utils.ts'
import {
  Kind,
  type DocumentNode,
  OperationTypeNode,
  type OperationDefinitionNode,
  type VariableDefinitionNode,
  type TypeNode,
  type NamedTypeNode,
} from 'graphql'
import { createRequire } from 'node:module'
import type { DeepPartial, DeepRequired } from '#shared/types/utils.ts'
import { uniqBy } from 'lodash-es'
import getUuid from '#shared/utils/getUuid.ts'
import { generateGraphqlMockId, hasNodeParent, setNodeParent } from './utils.ts'
import logger from './logger.ts'

const _require = createRequire(import.meta.url)
const introspection = _require('../../../../graphql/graphql_introspection.json')

export interface ResolversMeta {
  variables: Record<string, unknown>
  document: DocumentNode | undefined
  cached: boolean
}

type Resolver = (parent: any, defaults: any, meta: ResolversMeta) => any

interface Resolvers {
  [key: string]: Resolver
}

const factoriesModules = import.meta.glob<Resolver>('../factories/*.ts', {
  eager: true,
  import: 'default',
})

const storedObjects = new Map<string, any>()

export const getStoredMockedObject = <T>(
  type: string,
  id: number,
): DeepRequired<T> => {
  return storedObjects.get(convertToGraphQLId(type, id))
}

afterEach(() => {
  storedObjects.clear()
})

const factories: Resolvers = {}

// eslint-disable-next-line guard-for-in
for (const key in factoriesModules) {
  factories[key.replace(/\.\.\/factories\/(.*)\.ts$/, '$1')] =
    factoriesModules[key]
}

interface SchemaObjectType {
  kind: 'OBJECT'
  name: string
  fields: SchemaObjectField[]
}

interface SchemaEnumType {
  kind: 'ENUM'
  name: string
  enumValues: {
    name: string
    description: string
  }[]
}

interface SchemaObjectFieldType {
  kind: 'OBJECT' | 'ENUM' | 'LIST' | 'NON_NULL' | 'INPUT_OBJECT' | 'UNION'
  name: string
  ofType: null | SchemaObjectFieldType
}

interface SchemaObjectScalarFieldType {
  kind: 'SCALAR'
  name: string
  ofType: null
}

interface SchemaObjectField {
  name: string
  type: SchemaType
  args: SchemaObjectField[]
  isDeprecated?: boolean
  deprecatedReason?: string
  defaultValue?: unknown
}

interface SchemaScalarType {
  kind: 'SCALAR'
  name: string
}

interface SchemaUnionType {
  kind: 'UNION'
  possibleTypes: SchemaType[]
  name: string
}

interface SchemaInputObjectType {
  kind: 'INPUT_OBJECT'
  name: string
  fields: null
  inputFields: SchemaObjectField[]
}

type SchemaType =
  | SchemaObjectType
  | SchemaObjectFieldType
  | SchemaEnumType
  | SchemaScalarType
  | SchemaObjectScalarFieldType
  | SchemaUnionType
  | SchemaInputObjectType

const schemaTypes = introspection.data.__schema.types as SchemaType[]

const queriesTypes = {
  query: 'Queries',
  mutation: 'Mutations',
  subscription: 'Subscriptions',
}

const queries = schemaTypes.find(
  (type) => type.kind === 'OBJECT' && type.name === queriesTypes.query,
) as SchemaObjectType
const mutations = schemaTypes.find(
  (type) => type.kind === 'OBJECT' && type.name === queriesTypes.mutation,
) as SchemaObjectType
const subscriptions = schemaTypes.find(
  (type) => type.kind === 'OBJECT' && type.name === queriesTypes.subscription,
) as SchemaObjectType

const schemas = {
  query: queries,
  mutation: mutations,
  subscription: subscriptions,
}

export const getOperationDefinition = (
  operation: OperationTypeNode,
  name: string,
) => {
  const { fields } = schemas[operation]
  return fields.find((field) => field.name === name)!
}

// there are some commonly named fields that backend uses
// so we can assume what type they are
const commonStringGenerators: Record<string, () => string> = {
  note: () => faker.lorem.sentence(),
  heading: () => faker.lorem.sentence(2),
  label: () => faker.lorem.sentence(2),
  value: () => faker.lorem.sentence(),
  uid: () => faker.string.uuid(),
}

// generate default scalar values
const getScalarValue = (
  parent: any,
  fieldName: string,
  definition: SchemaScalarType,
): string | number | boolean | Record<string, unknown> => {
  switch (definition.name) {
    case 'Boolean':
      return faker.datatype.boolean()
    case 'Int':
      return faker.number.int({ min: 1, max: 1000 })
    case 'Float':
      return faker.number.float()
    case 'BinaryString':
      return faker.image.dataUri()
    case 'FormId':
      return getUuid()
    case 'ISO8601Date':
      return faker.date.recent().toISOString().substring(0, 10)
    case 'ISO8601DateTime':
      return faker.date.recent().toISOString()
    case 'ID':
      return generateGraphqlMockId(parent)
    case 'NonEmptyString':
    case 'String':
      return commonStringGenerators[fieldName]?.() || faker.lorem.word()
    case 'JSON':
      return {}
    default:
      throw new Error(`not implemented for ${definition.name}`)
  }
}

const isList = (definitionType: SchemaType): boolean => {
  if (definitionType.kind === 'LIST') {
    return true
  }
  return 'ofType' in definitionType && definitionType.ofType
    ? isList(definitionType.ofType)
    : false
}

export const getFieldData = (definitionType: SchemaType): any => {
  if (
    definitionType.kind === 'SCALAR' ||
    definitionType.kind === 'OBJECT' ||
    definitionType.kind === 'UNION' ||
    definitionType.kind === 'INPUT_OBJECT'
  )
    return definitionType
  if (definitionType.kind === 'ENUM')
    return getEnumDefinition(definitionType.name)
  return definitionType.ofType ? getFieldData(definitionType.ofType) : null
}

const getFieldInformation = (definitionType: SchemaType) => {
  const list = isList(definitionType)
  const field = getFieldData(definitionType)
  if (!field) {
    console.dir(definitionType, { depth: null })
    throw new Error(`cannot find type definition for ${definitionType.name}`)
  }
  return {
    list,
    field,
  }
}

const getFromCache = (value: any, meta: ResolversMeta) => {
  if (!meta.cached) return undefined
  const potentialId =
    value.id ||
    (value.internalId
      ? convertToGraphQLId(value.__typename, value.internalId)
      : null)
  if (!potentialId) {
    // try to guess Id from variables
    const type = value.__typename
    const lowercaseType = type[0].toLowerCase() + type.slice(1)
    const potentialIdKey = `${lowercaseType}Id`
    const id = meta.variables[potentialIdKey] as string | undefined
    if (id) return storedObjects.get(id)
    const potentialInternalIdKey = `${lowercaseType}InternalId`
    const internalId = meta.variables[potentialInternalIdKey] as
      | number
      | undefined
    if (!internalId) return undefined
    const gqlId = convertToGraphQLId(type, internalId)
    return storedObjects.get(gqlId)
  }
  if (storedObjects.has(potentialId)) {
    return storedObjects.get(potentialId)
  }
  return undefined
}

// merges cache with custom defaults recursively by modifying the original object
const deepMerge = (target: any, source: any): any => {
  // eslint-disable-next-line guard-for-in
  for (const key in source) {
    const value = source[key]

    if (typeof value === 'object' && value !== null) {
      if (Array.isArray(value)) {
        target[key] = value.map((v, index) => {
          return deepMerge(target[key]?.[index] || {}, v)
        })
      } else {
        target[key] = deepMerge(target[key] || {}, value)
      }
    } else {
      target[key] = value
    }
  }

  return target
}

const populateObjectFromVariables = (value: any, meta: ResolversMeta) => {
  const type = value.__typename
  const lowercaseType = type[0].toLowerCase() + type.slice(1)
  const potentialIdKey = `${lowercaseType}Id`
  if (meta.variables[potentialIdKey]) {
    value.id ??= meta.variables[potentialIdKey]
  }
  const potentialInternalIdKey = `${lowercaseType}InternalId`
  if (meta.variables[potentialInternalIdKey]) {
    value.id ??= convertToGraphQLId(
      value.__typename,
      meta.variables[potentialInternalIdKey] as number,
    )
    value.internalId ??= meta.variables[potentialInternalIdKey]
  }
}

const getObjectDefinitionFromUnion = (fieldDefinition: any) => {
  if (fieldDefinition.kind === 'UNION') {
    const unionDefinition = getUnionDefinition(fieldDefinition.name)
    const randomObjectDefinition = faker.helpers.arrayElement(
      unionDefinition.possibleTypes,
    )
    return getObjectDefinition(randomObjectDefinition.name)
  }
  return fieldDefinition
}

const buildObjectFromInformation = (
  parent: any,
  fieldName: string,
  { list, field }: { list: boolean; field: any },
  defaults: any,
  meta: ResolversMeta,
  // eslint-disable-next-line sonarjs/cognitive-complexity
) => {
  if (field.kind === 'UNION' && !defaults) {
    const factory = factories[field.name as 'Avatar']
    if (factory) {
      defaults = list
        ? faker.helpers.multiple(() => factory(parent, undefined, meta), {
            count: { min: 1, max: 5 },
          })
        : factory(parent, undefined, meta)
    }
  }
  if (!list) {
    const typeDefinition = getObjectDefinitionFromUnion(field)
    return generateGqlValue(parent, fieldName, typeDefinition, defaults, meta)
  }
  if (defaults) {
    const isUnion = field.kind === 'UNION'
    const builtList = defaults.map((item: any) => {
      const actualFieldType =
        isUnion && item.__typename
          ? getObjectDefinition(item.__typename)
          : field
      return generateGqlValue(parent, fieldName, actualFieldType, item, meta)
    })
    if (typeof builtList[0] === 'object' && builtList[0]?.id) {
      return uniqBy(builtList, 'id') // if autocmocker generates duplicates, remove them
    }
    return builtList
  }
  const typeDefinition = getObjectDefinitionFromUnion(field)
  const builtList = faker.helpers.multiple(
    () => generateGqlValue(parent, fieldName, typeDefinition, undefined, meta),
    { count: { min: 1, max: 5 } },
  )
  if (typeof builtList[0] === 'object' && builtList[0]?.id) {
    return uniqBy(builtList, 'id') // if autocmocker generates duplicates, remove them
  }
  return builtList
}

// we always generate full object because it might be reused later
// in another query with more parameters
const generateObject = (
  parent: Record<string, any> | undefined,
  definition: SchemaObjectType,
  defaults: Record<string, any> | undefined,
  meta: ResolversMeta,
  // eslint-disable-next-line sonarjs/cognitive-complexity
): Record<string, any> | null => {
  logger.log(
    'creating',
    definition.name,
    'from',
    parent?.__typename || 'the root',
    `(${parent?.id ? getIdFromGraphQLId(parent?.id) : null})`,
  )
  if (defaults === null) return null
  const type = definition.name
  const value = defaults ? { ...defaults } : {}
  value.__typename = type
  populateObjectFromVariables(value, meta)
  setNodeParent(value, parent)
  const cached = getFromCache(value, meta)
  if (cached !== undefined) {
    return defaults ? deepMerge(cached, defaults) : cached
  }
  const factory = factories[type as 'Avatar']
  if (factory) {
    const resolved = factory(parent, value, meta)
    // factory doesn't override custom defaults
    for (const key in resolved) {
      if (!(key in value)) {
        value[key] = resolved[key]
      } else if (
        value[key] &&
        typeof value[key] === 'object' &&
        resolved[key]
      ) {
        value[key] = deepMerge(resolved[key], value[key])
      }
    }
  }
  const factoryCached = getFromCache(value, meta)
  if (factoryCached !== undefined) {
    return factoryCached ? deepMerge(factoryCached, defaults) : factoryCached
  }
  if (value.id) {
    // I am not sure if this is a good change - it makes you think that ID is always numerical (even in prod) because of the tests
    // but it removes a lot of repetitive code - time will tell!
    if (typeof value.id !== 'string') {
      throw new Error(
        `id must be a string, got ${typeof value.id} inside ${type}`,
      )
    }
    // session has a unique base64 id
    if (type !== 'Session' && !value.id.startsWith('gid://zammad/')) {
      if (Number.isNaN(Number(value.id))) {
        throw new Error(
          `expected numerical or graphql id for ${type}, got ${value.id}`,
        )
      }
      const gqlId = convertToGraphQLId(type, value.id)
      logger.log(
        `received ${value.id} ID inside ${type}, rewriting to ${gqlId}`,
      )
      value.id = gqlId
    }
    storedObjects.set(value.id, value)
  }
  const needUpdateTotalCount =
    type.endsWith('Connection') && !('totalCount' in value)
  const buildField = (field: SchemaObjectField) => {
    const { name } = field
    // ignore null and undefined
    if (name in value && value[name] == null) {
      return
    }
    // if the object is already generated, keep it
    if (hasNodeParent(value[name])) {
      return
    }
    // by default, don't populate those fields since
    // first two can lead to recursions or inconsistent data
    // the "errors" should usually be "null" anyway
    // this is still possible to override with defaults
    if (
      !(name in value) &&
      (name === 'updatedBy' || name === 'createdBy' || name === 'errors')
    ) {
      value[name] = null
      return
    }
    // by default, all mutations are successful because errors are null
    if (
      field.type.kind === 'SCALAR' &&
      name === 'success' &&
      !(name in value)
    ) {
      value[name] = true
      return
    }
    value[name] = buildObjectFromInformation(
      value,
      name,
      getFieldInformation(field.type),
      value[name],
      meta,
    )
    if (meta.cached && name === 'id') {
      storedObjects.set(value.id, value)
    }
  }
  definition.fields!.forEach((field) => buildField(field))
  if (needUpdateTotalCount) {
    value.totalCount = value.edges.length
  }
  if (value.id && value.internalId) {
    value.internalId = getIdFromGraphQLId(value.id)
  }
  if (meta.cached && value.id) {
    storedObjects.set(value.id, value)
  }
  return value
}

export const getInputObjectDefinition = (name: string) => {
  const definition = schemaTypes.find(
    (type) => type.kind === 'INPUT_OBJECT' && type.name === name,
  ) as SchemaInputObjectType
  if (!definition) {
    throw new Error(`Input object definition not found for ${name}`)
  }
  return definition
}

export const getObjectDefinition = (name: string) => {
  const definition = schemaTypes.find(
    (type) => type.kind === 'OBJECT' && type.name === name,
  ) as SchemaObjectType
  if (!definition) {
    throw new Error(`Object definition not found for ${name}`)
  }
  return definition
}

const getUnionDefinition = (name: string) => {
  const definition = schemaTypes.find(
    (type) => type.kind === 'UNION' && type.name === name,
  ) as SchemaUnionType
  if (!definition) {
    throw new Error(`Union definition not found for ${name}`)
  }
  return definition
}

const getEnumDefinition = (name: string) => {
  const definition = schemaTypes.find(
    (type) => type.kind === 'ENUM' && type.name === name,
  ) as SchemaEnumType
  if (!definition) {
    throw new Error(`Enum definition not found for ${name}`)
  }
  return definition
}

const generateEnumValue = (definition: any): string => {
  return (faker.helpers.arrayElement(definition.enumValues) as { name: string })
    .name
}

const generateGqlValue = (
  parent: Record<string, any> | undefined,
  fieldName: string,
  typeDefinition: SchemaType,
  defaults: Record<string, any> | null | undefined,
  meta: ResolversMeta,
) => {
  if (defaults === null) return null
  if (typeDefinition.kind === 'OBJECT')
    return generateObject(
      parent,
      getObjectDefinition(typeDefinition.name),
      defaults,
      meta,
    )
  if (defaults !== undefined) return defaults
  if (typeDefinition.kind === 'ENUM') return generateEnumValue(typeDefinition)
  if (typeDefinition.kind === 'SCALAR')
    return getScalarValue(parent, fieldName, typeDefinition)
  logger.log(typeDefinition)
  throw new Error(`wrong definition for ${typeDefinition.name}`)
}

/**
 * Generates an object from a GraphQL type name.
 * You can provide a partial defaults object to make it more predictable.
 *
 * This function always generates a new object and never caches it.
 */
export const generateObjectData = <T>(
  typename: string,
  defaults?: DeepPartial<T>,
): T => {
  return generateObject(undefined, getObjectDefinition(typename), defaults, {
    document: undefined,
    variables: {},
    cached: false,
  }) as T
}

const getJsTypeFromScalar = (
  scalar: string,
): 'string' | 'number' | 'boolean' | null => {
  switch (scalar) {
    case 'Boolean':
      return 'boolean'
    case 'Int':
    case 'Float':
      return 'number'
    case 'ID':
    case 'BinaryString':
    case 'NonEmptyString':
    case 'FormId':
    case 'String':
    case 'ISO8601Date':
    case 'ISO8601DateTime':
      return 'string'
    case 'JSON':
    default:
      return null
  }
}

const createVariablesError = (
  definition: OperationDefinitionNode,
  message: string,
) => {
  return new Error(
    `(Variables error for ${definition.operation} ${definition.name?.value}) ${message}`,
  )
}

const validateSchemaValue = (
  definition: OperationDefinitionNode,
  data: SchemaObjectField,
  value: any,
  // eslint-disable-next-line sonarjs/cognitive-complexity
) => {
  const required = data.type.kind === 'NON_NULL'
  const { field, list } = getFieldInformation(data.type)
  if (value == null) {
    if (required && data.defaultValue == null) {
      throw createVariablesError(
        definition,
        `non-nullable field "${data.name}" is not defined`,
      )
    }
    return
  }
  if (list) {
    if (!Array.isArray(value)) {
      throw createVariablesError(
        definition,
        `expected array for "${data.name}", got ${typeof value}`,
      )
    }
    for (const item of value) {
      validateSchemaValue(definition, { ...data, type: field }, item)
    }
    return
  }
  if (field.kind === 'SCALAR') {
    const type = getJsTypeFromScalar(field.name)
    // eslint-disable-next-line valid-typeof
    if (type && typeof value !== type) {
      throw createVariablesError(
        definition,
        `expected ${type} for "${data.name}", got ${typeof value}`,
      )
    }
  }
  if (field.kind === 'ENUM') {
    const enumDefinition = getEnumDefinition(field.name)
    const enumValues = enumDefinition.enumValues.map(
      (enumValue) => enumValue.name,
    )
    if (!enumValues.includes(value)) {
      throw createVariablesError(
        definition,
        `${data.name} should be one of "${enumValues.join('", "')}", but instead got "${value}"`,
      )
    }
  }
  if (field.kind === 'INPUT_OBJECT') {
    if (typeof value !== 'object' || value === null) {
      throw createVariablesError(
        definition,
        `expected object for "${data.name}", got ${typeof value}`,
      )
    }

    const object = getInputObjectDefinition(field.name)
    const fields = new Set(object.inputFields.map((f) => f.name))
    for (const key in value) {
      if (!fields.has(key)) {
        throw createVariablesError(
          definition,
          `field "${key}" is not defined on ${field.name}`,
        )
      }
    }
    for (const field of object.inputFields) {
      const inputValue = value[field.name]
      validateSchemaValue(definition, field, inputValue)
    }
  }
}

const isVariableDefinitionList = (definition: VariableDefinitionNode) => {
  if (definition.type.kind === Kind.LIST_TYPE) return true
  if (definition.type.kind === Kind.NON_NULL_TYPE) {
    return definition.type.type.kind === Kind.LIST_TYPE
  }
  return false
}

const getVariableDefinitionField = (definition: TypeNode): NamedTypeNode => {
  if (definition.kind === Kind.NAMED_TYPE) return definition
  return getVariableDefinitionField(definition.type)
}

const buildFieldDefinitionFromVriablesDefinition = ({
  list,
  required,
  field,
}: {
  list: boolean
  required: boolean
  field: any
}) => {
  if (list && required) {
    return {
      kind: 'NON_NULL',
      ofType: {
        kind: 'LIST',
        ofType: field,
      },
    }
  }
  if (required) {
    return {
      kind: 'NON_NULL',
      ofType: field,
    }
  }
  if (list) {
    return {
      kind: 'LIST',
      ofType: field,
    }
  }
  return field
}

const validateQueryDefinitionVariables = (
  definition: OperationDefinitionNode,
  variableDefinition: VariableDefinitionNode,
  variables: Record<string, any>,
) => {
  const required = variableDefinition.type.kind === Kind.NON_NULL_TYPE
  const list = isVariableDefinitionList(variableDefinition)
  const field = getVariableDefinitionField(variableDefinition.type)
  const fieldDefinitions = schemaTypes.filter(
    (type) => type.name === field.name.value,
  )
  if (fieldDefinitions.length === 0) {
    throw createVariablesError(
      definition,
      `Cannot find definition for "${field.name.value}"`,
    )
  }
  if (fieldDefinitions.length > 1) {
    throw createVariablesError(
      definition,
      `Multiple definitions for "${field.name.value}": ${fieldDefinitions.map((type) => type.kind).join(', ')}`,
    )
  }
  const name = variableDefinition.variable.name.value
  const defaultValue = (() => {
    const { defaultValue } = variableDefinition
    if (typeof defaultValue === 'undefined') return undefined
    if ('value' in defaultValue) return defaultValue.value
    if (defaultValue.kind === Kind.LIST) return []
    if (defaultValue.kind === Kind.NULL) return null
    // we don't care for values inside the object
    return {}
  })()
  validateSchemaValue(
    definition,
    {
      name,
      type: buildFieldDefinitionFromVriablesDefinition({
        required,
        list,
        field: fieldDefinitions[0],
      }),
      args: [],
      defaultValue,
    },
    variables[name],
  )
}

export const validateOperationVariables = (
  definition: OperationDefinitionNode,
  variables: Record<string, any>,
) => {
  const name = definition.name?.value
  if (!name || !definition.variableDefinitions) return
  const variablesNames = definition.variableDefinitions.map(
    (variableDefinition) => variableDefinition.variable.name.value,
  )
  for (const variable in variables) {
    if (!variablesNames.includes(variable)) {
      throw createVariablesError(
        definition,
        `field "${variable}" is not defined on ${definition.operation} ${name}`,
      )
    }
  }
  definition.variableDefinitions.forEach((variableDefinition) => {
    validateQueryDefinitionVariables(definition, variableDefinition, variables)
  })
}

export const mockOperation = (
  document: DocumentNode,
  variables: Record<string, unknown>,
  defaults?: Record<string, any>,
  // eslint-disable-next-line sonarjs/cognitive-complexity
): Record<string, any> => {
  const definition = document.definitions[0]
  if (definition.kind !== Kind.OPERATION_DEFINITION) {
    throw new Error(`${(definition as any).name} is not an operation`)
  }
  const { operation, name, selectionSet } = definition
  const operationName = name!.value!
  const operationType = getOperationDefinition(operation, operationName)
  const query: any = { __typename: queriesTypes[operation] }
  const rootName = operationType.name
  logger.log(`[MOCKER] mocking "${rootName}" ${operation}`)

  const information = getFieldInformation(operationType.type)

  if (selectionSet.selections.length === 1) {
    const selection = selectionSet.selections[0]
    if (selection.kind !== Kind.FIELD) {
      throw new Error(
        `unsupported selection kind ${selectionSet.selections[0].kind}`,
      )
    }
    if (selection.name.value !== rootName) {
      throw new Error(
        `unsupported selection name ${selection.name.value} (${operation} is ${operationType.name})`,
      )
    }
    query[rootName] = buildObjectFromInformation(
      query,
      rootName,
      information,
      defaults?.[rootName],
      {
        document,
        variables,
        cached: true,
      },
    )
  } else {
    selectionSet.selections.forEach((selection) => {
      if (selection.kind !== Kind.FIELD) {
        throw new Error(`unsupported selection kind ${selection.kind}`)
      }
      const operationType = getOperationDefinition(operation, operationName)
      const fieldName = selection.alias?.value || selection.name.value
      query[fieldName] = buildObjectFromInformation(
        query,
        rootName,
        getFieldInformation(operationType.type),
        defaults?.[rootName],
        {
          document,
          variables,
          cached: true,
        },
      )
    })
  }

  return query
}
