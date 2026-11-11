// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Dispatches each .graphql document to the native v5 generator or the stock
// compat one, so documents migrate to the v5 composable shape one by one via
// ./vueApolloV5Documents.js. A single plugin instead of two `generates`
// entries, because the near-operation-file preset calls the plugin once per
// output file and a second entry would write every fragment file twice.

const stockPlugin = require('@graphql-codegen/typescript-vue-apollo')

const { isVueApolloV5Document } = require('./vueApolloV5Documents.js')
const vueApolloV5Plugin = require('./vueApolloV5Plugin.js')

/** @type {import('@graphql-codegen/plugin-helpers').PluginFunction} */
const plugin = (schema, documents, config, info) => {
  if (documents[0]?.location && isVueApolloV5Document(documents[0].location)) {
    return vueApolloV5Plugin.plugin(schema, documents, config, info)
  }

  // Not yet allowlisted documents keep the v4 call signatures on vue-apollo v5
  // internals until their call sites are migrated to the native v5 API.
  return stockPlugin.plugin(
    schema,
    documents,
    {
      ...config,
      vueApolloComposableImportFrom: '@vue/apollo-composable/compat',
      vueCompositionApiImportFrom: 'vue',
    },
    info,
  )
}

module.exports = { plugin, validate: stockPlugin.validate }
