// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/** @type {import('@graphql-codegen/cli').CodegenConfig['generates'][string]} */
const mockerPreset = {
  documents: ['app/frontend/**/{queries,mutations,subscriptions}/**/*.graphql'],
  preset: 'near-operation-file',
  presetConfig: {
    baseTypesPath: '~#shared/graphql/types.ts',
    importTypesNamespace: '',
    extension: '.mocks.ts',
  },
  plugins: ['./app/frontend/build/mocksGraphqlPlugin.js'],
  config: {
    importOperationTypesFrom: 'Types',
    skipDocumentsValidation: {
      skipValidationAgainstSchema: true,
    },
  },
}

const documents = ['app/frontend/shared/**/*.graphql', 'app/frontend/apps/**/*.graphql']

const scalars = {
  BinaryString: 'string',
  NonEmptyString: 'string',
  FormId: 'string',
  ISO8601Date: 'string',
  ISO8601DateTime: 'string',
  JSON: 'any',
  UriHttpString: 'string',
}

/** @type {import('@graphql-codegen/cli').CodegenConfig} */
const config = {
  overwrite: true,
  schema: 'app/graphql/graphql_introspection.json',
  config: {
    vueCompositionApiImportFrom: 'vue',
    addDocBlocks: false,
  },
  generates: {
    './app/frontend/shared/graphql/schema-types.ts': {
      config: {
        scalars,
      },
      plugins: ['typescript'],
    },
    './app/frontend/shared/graphql/types.ts': {
      documents,
      config: {
        scalars,
        importSchemaTypesFrom: './app/frontend/shared/graphql/schema-types.ts',
        namespacedImportName: 'Types',
        // eslint-disable-next-line zammad/zammad-detect-translatable-string
        maybeValue: 'T | null | undefined',
        nonOptionalTypename: true,
        skipTypeNameForRoot: true,
      },
      plugins: [
        {
          add: {
            content: ["export * from './schema-types'", 'export type { Exact }'],
          },
        },
        'typescript-operations',
      ],
    },
    './app/frontend/': {
      documents,
      preset: 'near-operation-file',
      presetConfig: {
        baseTypesPath: '~#shared/graphql/types.ts',
        importTypesNamespace: '',
        extension: '.api.ts',
      },
      plugins: ['typescript-vue-apollo'],
      config: {
        importOperationTypesFrom: 'Types',
      },
    },
    // generate mocks
    './app/frontend/apps/': mockerPreset,
    './app/frontend/shared/': mockerPreset,
  },
}

module.exports = config
