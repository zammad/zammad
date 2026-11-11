// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Packages not listed here are split automatically.
const vendorChunks = {
  vue: [
    'vue',
    '@vue/runtime-core',
    '@vue/runtime-dom',
    '@vue/reactivity',
    '@vue/shared',
    'vue-router',
    'pinia',
  ],
  lodash: ['lodash-es'],
  linkifyjs: ['linkifyjs', 'linkify-string'],
  // Only lazily loaded code uses the charts, so this chunk stays out of the startup download.
  echarts: ['echarts', 'zrender', 'vue-echarts'],
  graphql: [
    'graphql',
    'graphql-ruby-client',
    'graphql-tag',
    '@apollo/client',
    '@vue/apollo-composable',
    'rxjs',
    '@rails/actioncable',
  ],
  formkit: [
    '@formkit/core',
    '@formkit/dev',
    // @formkit/drag-and-drop stays out: it is desktop-only and this chunk is shared with mobile.
    '@formkit/i18n',
    '@formkit/inputs',
    '@formkit/rules',
    '@formkit/themes',
    '@formkit/utils',
    '@formkit/validation',
    '@formkit/vue',
  ],
}

// Matches the package path after the last `node_modules/` as a whole segment, so that
// `vue` does not capture `vue-echarts` and the pnpm store path is not involved.
const isInPackages = (id, packages) => {
  const marker = 'node_modules/'
  const start = id.lastIndexOf(marker)
  if (start === -1) return false

  const packagePath = id.slice(start + marker.length)
  return packages.some((pkg) => packagePath.startsWith(`${pkg}/`))
}

// A group captures its packages together with their dependencies, and a module goes
// to the first group that reaches it. The Vue runtime is listed first so that it has
// a fixed place instead of landing in whichever other group pulls it in first.
export const vendorChunkGroups = Object.entries(vendorChunks).map(([name, packages]) => ({
  name,
  test: (id) => isInPackages(id, packages),
}))
