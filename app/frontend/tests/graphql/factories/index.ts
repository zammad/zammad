// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable no-restricted-syntax */
/* eslint-disable no-use-before-define */

import { faker } from '@faker-js/faker'
import {
  convertToGraphQLId,
  getIdFromGraphQLId,
} from '#shared/graphql/utils.ts'

import { Kind, type DocumentNode, OperationTypeNode } from 'graphql'
import { createRequire } from 'node:module'
import type { DeepPartial, DeepRequired } from '#shared/types/utils.ts'
import { generateGraphqlMockId, hasNodeParent, setNodeParent } from './utils.ts'

const _require = createRequire(import.meta.url)
const introspection = _require('../../../../graphql/graphql_introspection.json')

export interface ResolversMeta {
  variables: Record<string, unknown>
  document: DocumentNode | undefined
  cached: boolean
}

export interface Resolvers {
  [key: string]: (parent: any, defaults: any, meta: ResolversMeta) => any
}

const factoriesModules = import.meta.glob(
  ['./*.ts', '!./index.ts', '!./utils.ts', '!./mocks.ts'],
  { eager: true, import: 'default' },
) as Resolvers

const log = (...mesages: unknown[]) => {
  if (process.env.VITEST_LOG_GQL_FACTORY) {
    console.log(...mesages)
  }
}

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
  factories[key.replace(/\.\/(.*)\.ts/, '$1')] = factoriesModules[key]
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
  kind: 'OBJECT' | 'ENUM' | 'LIST' | 'NON_NULL' | 'INPUT_OBJECT'
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
}

interface SchemaScalarType {
  kind: 'SCALAR'
  name: string
}

type SchemaType =
  | SchemaObjectType
  | SchemaObjectFieldType
  | SchemaEnumType
  | SchemaScalarType
  | SchemaObjectScalarFieldType

const schemaTypes = introspection.data.__schema.types as SchemaType[]

const queries = schemaTypes.find(
  (type) => type.kind === 'OBJECT' && type.name === 'Queries',
) as SchemaObjectType
const mutations = schemaTypes.find(
  (type) => type.kind === 'OBJECT' && type.name === 'Mutations',
) as SchemaObjectType
const subscriptions = schemaTypes.find(
  (type) => type.kind === 'OBJECT' && type.name === 'Subscriptions',
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

const commonStringGenerators: Record<string, () => string> = {
  note: () => faker.lorem.sentence(),
  heading: () => faker.lorem.sentence(2),
  label: () => faker.lorem.sentence(2),
  value: () => faker.lorem.sentence(),
  uid: () => faker.string.uuid(),
}

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
    case 'FormId': {
      const formId =
        faker.date.recent() + Math.floor(Math.random() * 99999).toString()
      return formId.substring(formId.length - 9, 9)
    }
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
  if (definitionType.kind === 'SCALAR' || definitionType.kind === 'OBJECT')
    return definitionType
  if (definitionType.kind === 'ENUM')
    return getEnumDefinition(definitionType.name)
  return definitionType.ofType ? getFieldData(definitionType.ofType) : null
}

const getFieldInformation = (definitionType: SchemaType) => {
  const list = isList(definitionType)
  const field = getFieldData(definitionType)
  if (!field) {
    log(definitionType)
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

    if (typeof value === 'object') {
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

const generateObject = (
  parent: Record<string, any> | undefined,
  definition: SchemaObjectType,
  defaults: Record<string, any> | undefined,
  meta: ResolversMeta,
  // eslint-disable-next-line sonarjs/cognitive-complexity
): Record<string, any> | null => {
  log(
    'creating',
    definition.name,
    'from',
    parent?.__typename,
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
      } else if (value[key] && typeof value[key] === 'object') {
        value[key] = deepMerge(resolved[key], value[key])
      }
    }
  }
  const factoryCached = getFromCache(value, meta)
  if (factoryCached !== undefined) {
    return factoryCached ? deepMerge(factoryCached, defaults) : factoryCached
  }
  const needUpdateTotalCount =
    type.endsWith('Connection') && !('totalCount' in value)
  definition.fields!.forEach((field) => {
    const { name } = field
    // ignore null and undefined
    if (name in value && value[name] == null) {
      return
    }
    if (hasNodeParent(value[name])) {
      return
    }
    // by default, don't populate those fields since
    // first two can lead to recursions or inconsistent data
    // the "errors" should usually be "null" anyway
    if (name === 'updatedBy' || name === 'createdBy' || name === 'errors') {
      value[name] = null
      return
    }
    const { list, field: fieldType } = getFieldInformation(field.type)
    if (list) {
      if (name in value) {
        value[name] = value[name].map((item: any) => {
          return generateGqlValue(value, name, fieldType, item, meta)
        })
      } else {
        value[name] = faker.helpers.multiple(
          () => generateGqlValue(value, name, fieldType, undefined, meta),
          { count: { min: 1, max: 5 } },
        )
      }
    } else {
      value[name] = generateGqlValue(value, name, fieldType, value[name], meta)
    }
    if (meta.cached && name === 'id') {
      storedObjects.set(value.id, value)
    }
  })
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

export const getObjectDefinition = (name: string) => {
  const definition = schemaTypes.find(
    (type) => type.kind === 'OBJECT' && type.name === name,
  ) as SchemaObjectType
  if (!definition) {
    throw new Error(`Object definition not found for ${name}`)
  }
  return definition
}

const getEnumDefinition = (name: string) => {
  const definition = schemaTypes.find(
    (type) => type.kind === 'ENUM' && type.name === name,
  ) as SchemaObjectType
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
  defaults: Record<string, any> | undefined,
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
  log(typeDefinition)
  throw new Error(`wrong definition for ${typeDefinition.name}`)
}

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

const results = new WeakMap<DocumentNode, unknown>()

export const getGqlOperationResult = <T>(document: DocumentNode): T => {
  return results.get(document) as T
}

export const mockOperation = (
  document: DocumentNode,
  variables: Record<string, unknown>,
  defaults?: Record<string, any>,
): Record<string, any> => {
  const definition = document.definitions[0]
  if (definition.kind !== Kind.OPERATION_DEFINITION) {
    throw new Error(`${(definition as any).name} is not an operation`)
  }
  const { operation, name, selectionSet } = definition
  const operationName = name!.value!
  const operationType = getOperationDefinition(operation, operationName)
  const query: any = {}
  results.set(document, query)
  const rootName = operationType.name
  log(`mocking ${rootName}`)

  const queryValueDefinition = getObjectDefinition(
    getFieldInformation(operationType.type).field.name,
  )

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
    query[rootName] = generateObject(
      query,
      queryValueDefinition,
      defaults?.[rootName],
      { document, variables, cached: true },
    )
  } else {
    query[rootName] = {}

    selectionSet.selections.forEach((selection) => {
      if (selection.kind !== Kind.FIELD) {
        throw new Error(`unsupported selection kind ${selection.kind}`)
      }
      const operationType = getOperationDefinition(operation, operationName)
      const fieldName = selection.alias?.value || selection.name.value
      const operationDefinition = getObjectDefinition(
        getFieldInformation(operationType.type).field.name,
      )
      query[rootName][fieldName] = generateObject(
        query[rootName],
        operationDefinition,
        defaults?.[rootName][fieldName],
        { document, variables, cached: true },
      )
    })
  }

  return query
}
