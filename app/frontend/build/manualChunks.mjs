// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { splitVendorChunk } from 'vite'

const matchers = [
  {
    vendor: false,
    matcher: (id) => id.includes('commonjsHelpers.js'),
    chunk: 'commonjsHelpers',
  },
  {
    vendor: false,
    matcher: (id) => id.includes('vite/preload-helper'),
    chunk: 'vite',
  },
  {
    vendor: false,
    matcher: (id) => id.endsWith('/routes.ts'),
    chunk: 'routes',
  },
  {
    vendor: true,
    matcher: (id) => id.includes('@vue/apollo'),
    chunk: 'apollo',
  },
  {
    vendor: false,
    matcher: (id) => id.includes('frontend/shared/server'),
    chunk: 'apollo',
  },
  {
    vendor: true,
    matcher: (id) => id.includes('node_modules/lodash-es'),
    chunk: 'lodash',
  },
  {
    vendor: true,
    matcher: (id) => /node_modules\/@formkit/.test(id),
    chunk: 'formkit',
  },
  {
    vendor: true,
    matcher: (id) => /node_modules\/@?vue/.test(id),
    chunk: 'vue',
  },
]

/**
 * @returns {import("vite").Plugin}
 */
const ManualChunksPlugin = () => {
  const getChunk = splitVendorChunk()

  return {
    name: 'zammad:manual-chunks',
    // eslint-disable-next-line sonarjs/cognitive-complexity
    config() {
      return {
        build: {
          rollupOptions: {
            output: {
              manualChunks(id, api) {
                const chunk = getChunk(id, api)

                // FieldEditor is a special case, it's a dynamic import with a large dependency
                if (!chunk && id.includes('FieldEditor')) {
                  return
                }

                if (!chunk) {
                  for (const { vendor, matcher, chunk } of matchers) {
                    if (vendor === false && matcher(id)) {
                      return chunk
                    }
                  }
                }

                if (chunk !== 'vendor') return chunk

                for (const { vendor, matcher, chunk } of matchers) {
                  if (vendor === true && matcher(id, api)) {
                    return chunk
                  }
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

export default ManualChunksPlugin
