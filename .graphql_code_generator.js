// @ts-check

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

/** @type {import('@graphql-codegen/cli').CodegenConfig} */
const config = {
  overwrite: true,
  schema: 'app/graphql/graphql_introspection.json',
  config: {
    vueCompositionApiImportFrom: 'vue',
    addDocBlocks: false,
  },
  generates: {
    './app/frontend/shared/graphql/types.ts': {
      documents: [
        'app/frontend/shared/**/*.graphql',
        'app/frontend/apps/**/*.graphql',
      ],
      config: {
        scalars: {
          BinaryString: 'string',
          NonEmptyString: 'string',
          FormId: 'string',
          ISO8601Date: 'string',
          ISO8601DateTime: 'string',
          UriHttpString: 'string',
        },
      },
      plugins: ['typescript', 'typescript-operations'],
    },
    './app/frontend/': {
      documents: [
        'app/frontend/shared/**/*.graphql',
        'app/frontend/apps/**/*.graphql',
      ],
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
