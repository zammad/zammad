// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'

import { vendorChunkGroups } from '../vendorChunks.mjs'

const chunkOf = (id: string) => vendorChunkGroups.find((group) => group.test(id))?.name

const pnpm = (storeEntry: string, packagePath: string) =>
  `/zammad/node_modules/.pnpm/${storeEntry}/node_modules/${packagePath}`

describe('vendor chunk groups', () => {
  it.each([
    ['vue', pnpm('vue@3.5.43_typescript@6.0.3', 'vue/dist/vue.runtime.esm-bundler.js')],
    ['vue', pnpm('@vue+runtime-core@3.5.43', '@vue/runtime-core/dist/runtime-core.esm-bundler.js')],
    ['echarts', pnpm('echarts@6.1.0', 'echarts/lib/chart/bar.js')],
    ['echarts', pnpm('zrender@6.1.0', 'zrender/lib/canvas/Painter.js')],
    ['formkit', pnpm('@formkit+core@2.1.2', '@formkit/core/dist/index.mjs')],
    ['lodash', '/zammad/node_modules/lodash-es/debounce.js'],
  ])('puts a module of an exact package into the %s chunk', (chunk, id) => {
    expect(chunkOf(id)).toBe(chunk)
  })

  it.each([
    [
      'echarts',
      pnpm(
        'vue-echarts@8.3.1_echarts@6.1.0_vue@3.5.43_typescript@6.0.3_',
        'vue-echarts/dist/index.js',
      ),
    ],
    [
      'graphql',
      pnpm(
        '@vue+apollo-composable@5.0.0-alpha.4_@apollo+client@4.3.5_graphql@16.14.2_vue@3.5.43',
        '@vue/apollo-composable/dist/index.mjs',
      ),
    ],
    [
      'graphql',
      pnpm(
        'graphql-ruby-client@1.16.0_@apollo+client@4.3.5_graphql@16.14.2',
        'graphql-ruby-client/subscriptions/ActionCableLink.js',
      ),
    ],
  ])('ignores a peer dependency in the pnpm store path for the %s chunk', (chunk, id) => {
    expect(chunkOf(id)).toBe(chunk)
  })

  it.each([
    pnpm(
      'vue-advanced-cropper@2.8.9_vue@3.5.43_typescript@6.0.3_',
      'vue-advanced-cropper/dist/index.es.js',
    ),
    pnpm(
      'vue-easy-lightbox@1.19.0_vue@3.5.43_typescript@6.0.3_',
      'vue-easy-lightbox/dist/index.js',
    ),
    pnpm(
      'vue3-draggable-resizable@1.6.5',
      'vue3-draggable-resizable/dist/Vue3DraggableResizable.common.js',
    ),
    pnpm('@formkit+drag-and-drop@0.5.3', '@formkit/drag-and-drop/dist/index.mjs'),
    '/zammad/node_modules/lodash/debounce.js',
  ])('leaves a similarly named package to automatic splitting: %s', (id) => {
    expect(chunkOf(id)).toBeUndefined()
  })

  it('leaves application code to automatic splitting', () => {
    expect(
      chunkOf('/zammad/app/frontend/shared/components/CommonBarChart/CommonBarChart.vue'),
    ).toBeUndefined()
  })
})
