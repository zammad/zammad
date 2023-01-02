// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const { splitVendorChunk } = require('vite')

const graphqlChunk = ['graphql', '@apollo', '@vue/apollo']

const isGraphqlChunk = (id) =>
  graphqlChunk.some((chunk) => id.includes(`node_modules/${chunk}`))

/**
 * @returns {import("vite").Plugin}
 */
const PluginManualChunks = () => {
  const getChunk = splitVendorChunk()

  const graphqlIds = new Set()

  return {
    name: 'zammad:manual-chunks',
    config() {
      return {
        build: {
          rollupOptions: {
            output: {
              manualChunks(id, api) {
                const chunk = getChunk(id, api)

                // TODO why keep it in js?
                // maybe put it inside html?
                // al it does is appends a node with svgs
                if (id === 'virtual:svg-icons-register') {
                  return 'icons'
                }

                if (chunk !== 'vendor') return chunk

                if (id.includes('node_modules/lodash-es')) {
                  return 'lodash'
                }

                const { importers } = api.getModuleInfo(id)

                if (
                  graphqlIds.has(id) ||
                  isGraphqlChunk(id) ||
                  importers.some(isGraphqlChunk)
                ) {
                  importers.forEach(() => graphqlIds.add(id))
                  return 'graphql'
                }

                if (/node_modules\/@?vue/.test(id)) {
                  return 'vue'
                }

                return 'vendor'
              },
            },
          },
        },
      }
    },
  }
}

module.exports = PluginManualChunks
