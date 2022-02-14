// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// We need babel for the test envoirment, to have the vite meta glob transformation in the test context.
module.exports = {
  presets: [
    [
      '@babel/preset-env',
      {
        targets: { node: 'current' },
      },
    ],
    '@babel/preset-typescript',
  ],
  plugins: [
    '@babel/plugin-transform-runtime',
    'babel-plugin-transform-vite-meta-glob',
  ],
}
