// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const { loadConfigFromFile, mergeConfig } = require('vite')
const postcss = require('postcss')

module.exports = {
  stories: [
    '../../app/**/*.stories.mdx',
    '../../app/**/*.stories.@(js|jsx|ts|tsx)',
  ],
  addons: [
    '@storybook/addon-links',
    '@storybook/addon-essentials',
    {
      name: '@storybook/addon-postcss',
      options: {
        cssLoaderOptions: {
          // When you have splitted your css over multiple files
          // and use @import('./other-styles.css')
          importLoaders: 1,
        },
        postcssLoaderOptions: {
          // When using postCSS 8
          implementation: postcss,
        },
      },
    },
  ],
  framework: '@storybook/vue3',
  core: {
    builder: 'storybook-builder-vite',
  },
  async viteFinal(storybookViteConfig) {
    const { config } = await loadConfigFromFile(
      { mode: 'storybook' }, // env
      '../vite.config.ts', // config path, relative to root
    )
    return mergeConfig(storybookViteConfig, {
      ...config,

      server: {
        fs: {
          // Allow serving files from one level up to the project root
          allow: ['..'],
        },
      },
      publicDir: '../public',

      // Manually specify plugins to avoid conflicts.
      plugins: [
        config.plugins.find((plugin) => plugin.name === 'vite:svg-icons'),
      ],
    })
  },
}
