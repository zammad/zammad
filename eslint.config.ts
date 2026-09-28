// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import fs from 'fs'
import path from 'path'

import { defineConfigWithVueTs, vueTsConfigs } from '@vue/eslint-config-typescript'
import { globalIgnores } from 'eslint/config'
import betterTailwindcss from 'eslint-plugin-better-tailwindcss'
// @ts-ignore
import importPlugin from 'eslint-plugin-import-x'
import eslintConfigPrettier from 'eslint-config-prettier'
import oxlint from 'eslint-plugin-oxlint'
import pluginSecurity from 'eslint-plugin-security'
import pluginVue from 'eslint-plugin-vue'
import vuejsAccesibility from 'eslint-plugin-vuejs-accessibility'
import zammad from 'eslint-plugin-zammad/lib/index.js'

const mobilePagesDir = path.resolve(__dirname, 'app/frontend/apps/mobile/pages')
const mobilePagesFolder = fs.readdirSync(mobilePagesDir)

const desktopPagesDir = path.resolve(__dirname, 'app/frontend/apps/desktop/pages')
const desktopPagesFolder = fs.readdirSync(desktopPagesDir)

const testFiles = [
  'app/frontend/tests/**',
  'app/frontend/**/__tests__/**',
  'app/frontend/**/*.spec.*',
  'app/frontend/cypress/**',
  '.eslint-plugin-zammad/**',
]

export default defineConfigWithVueTs(
  {
    name: 'app/files-to-lint',
    files: ['**/*.{js,jsx,ts,mts,tsx,vue}'],
  },
  globalIgnores([
    'app/frontend/**/graphql/**/*.ts',
    '!app/frontend/tests/graphql/**/*.ts',
    'app/frontend/shared/graphql/schema-types.ts',
    'app/frontend/shared/graphql/types.ts',
    'app/frontend/shared/types/config.ts',
    'tmp/**/*',
    '**/*.snapshot.txt',
    'eslint.config.ts',
    'app/frontend/build/mocksGraphqlPlugin.js',
    'app/frontend/build/graphqlDocumentExtensions/transform.js',
    'app/frontend/build/graphqlDocumentExtensions/mergeDocument.js',
    '.eslint-plugin-zammad/lib/index.js',
    '.eslint-plugin-zammad/tests/**/*.js',
    'public/assets/tests/**/*.js',
  ]),

  // Base Vue and TypeScript configs - these handle parsing automatically
  pluginVue.configs['flat/recommended'],
  vueTsConfigs.recommended,
  pluginSecurity.configs.recommended,
  vuejsAccesibility.configs['flat/recommended'],

  // @ts-ignore
  {
    name: 'app/zammad-rules',
    plugins: { zammad },
    rules: {
      'zammad/zammad-copyright': 'error',
      'zammad/zammad-detect-translatable-string': 'error',
      'zammad/zammad-tailwind-ltr': 'error',
      'zammad/zammad-symbol-description': 'error',
    },
  },

  {
    name: 'app/tailwindcss',
    files: ['app/frontend/**/*.{js,ts,vue}'],
    ignores: testFiles,
    plugins: betterTailwindcss.configs.recommended.plugins,
    rules: {
      ...betterTailwindcss.configs.recommended.rules,
      // Conflicts with the `printWidth` of oxfmt.
      'better-tailwindcss/enforce-consistent-line-wrapping': 'off',
      'better-tailwindcss/enforce-canonical-classes': 'error',
      'better-tailwindcss/no-unknown-classes': [
        'error',
        {
          // Custom classes for stylesheets, scoped styles, scripts and tests.
          ignore: [
            '^[A-Z][A-Za-z]*$',
            '^(avatar-selected|border-shadow-b|bottom-navigation|color-indicator|content|cropper)$',
            '^(draggable|editor-action-popover|editor-overflow-popover|field-autocomplete-dialog)$',
            '^(file-list|formkit-link|icon|indicator|inner-article-body|left|line-more)$',
            '^(line-more-wrapper|line-new|object-attributes?|object-attribute-spanned-column)$',
            '^(popover|print-area|progress-bar|select-dialog|select-overlay|show-action-bar)$',
            '^(select-scroll-shadows(--alt|--base)?|(bottom|show|top)-gradient)$',
            '^(ticket-detail-grid-full|vip|window|wrapper)$',
          ],
        },
      ],
    },
    settings: {
      // Shared code is checked against the desktop stylesheet.
      'better-tailwindcss': {
        // Editors may run ESLint from a subdirectory, which breaks the relative entry points.
        cwd: __dirname,
        entryPoint: 'app/frontend/apps/desktop/styles/main.css',
      },
    },
  },

  {
    name: 'app/tailwindcss/mobile',
    files: ['app/frontend/apps/mobile/**'],
    settings: {
      'better-tailwindcss': {
        entryPoint: 'app/frontend/apps/mobile/styles/main.css',
      },
    },
  },

  {
    name: 'app/plugin-security',
    rules: {
      'security/detect-object-injection': 'off',
      'security/detect-non-literal-fs-filename': 'off',
      'security/detect-non-literal-regexp': 'off',
      'security/detect-child-process': 'off',
      'security/detect-bidi-characters': 'off',
    },
  },

  {
    name: 'app/vuejs',
    rules: {
      'vue/require-default-prop': 'off',
      'vue/multi-word-component-names': 'off',
      'vue/define-emits-declaration': ['error', 'type-literal'],
      'vue/v-bind-style': ['error', 'shorthand'],
      'vue/v-on-style': ['error', 'shorthand'],
      'vue/v-slot-style': ['error', 'shorthand'],
      'vue/custom-event-name-casing': ['error', 'kebab-case', { ignores: ['/^update:/'] }],
      'vue/attribute-hyphenation': 'error',
    },
  },

  {
    name: 'app/imports',
    plugins: {
      import: importPlugin,
    },
    rules: {
      'import/no-extraneous-dependencies': 'off',
      'import/extensions': ['error', 'ignorePackages'],
      'import/prefer-default-export': 'off',
      'import/no-restricted-paths': [
        'error',
        {
          zones: [
            // restrict import inside shared context from app context
            {
              target: './app/frontend/shared',
              from: './app/frontend/apps',
            },
            {
              target: './app/frontend/apps/desktop',
              from: './app/frontend/apps/mobile',
            },
            {
              target: './app/frontend/apps/mobile',
              from: './app/frontend/apps/desktop',
            },
            // restrict imports between different pages folder
            ...mobilePagesFolder.map((page) => {
              return {
                target: `./app/frontend/apps/mobile/pages/!(${page})/**/*`,
                from: `./app/frontend/apps/mobile/pages/${page}/**/*`,
              }
            }),
            ...desktopPagesFolder.map((page) => {
              return {
                target: `./app/frontend/apps/desktop/pages/!(${page})/**/*`,
                from: `./app/frontend/apps/desktop/pages/${page}/**/*`,
              }
            }),
          ],
        },
      ],
      'import/order': [
        'error',
        {
          groups: [
            'builtin',
            'external',
            'internal',
            'parent',
            'sibling',
            'index',
            'object',
            'type',
          ],
          pathGroups: [
            {
              pattern: '#tests/**',
              group: 'internal',
              position: 'before',
            },
            {
              pattern: '#cy/**',
              group: 'internal',
              position: 'before',
            },
            {
              pattern: '#shared/**',
              group: 'internal',
              position: 'before',
            },
            {
              pattern: '#desktop/**',
              group: 'internal',
            },
            {
              pattern: '#mobile/**',
              group: 'internal',
            },
            {
              pattern: '**/types.ts',
              group: 'type',
              position: 'after',
            },
          ],
          'newlines-between': 'always',
          alphabetize: { order: 'asc', caseInsensitive: true },
        },
      ],
    },
    settings: {
      'import/core-modules': ['virtual:pwa-register'],
      'import/parsers': {
        '@typescript-eslint/parser': ['.ts', '.tsx', '.vue'],
      },
      'import/resolver': {
        typescript: {
          alwaysTryTypes: true,
        },
        alias: {
          map: [
            [
              'vue-easy-lightbox/dist/external-css/vue-easy-lightbox.css',
              path.resolve(
                __dirname,
                'node_modules/vue-easy-lightbox/dist/external-css/vue-easy-lightbox.css',
              ),
            ],
          ],
          extensions: ['.js', '.jsx', '.ts', '.tsx', '.vue'],
        },
        node: {
          extensions: ['.js', '.jsx', '.ts', '.tsx', '.vue'],
        },
      },
    },
  },

  {
    name: 'app/override/tests',
    files: testFiles,
    rules: {
      'zammad/zammad-tailwind-ltr': 'off',
      'zammad/zammad-detect-translatable-string': 'off',
    },
  },

  {
    name: 'app/typescript',
    rules: {
      '@typescript-eslint/no-non-null-assertion': 'off',
      '@typescript-eslint/no-shadow': 'off',
      '@typescript-eslint/no-explicit-any': ['error', { ignoreRestArgs: true }],
      '@typescript-eslint/naming-convention': [
        'error',
        {
          selector: 'enumMember',
          format: ['StrictPascalCase'],
        },
        {
          selector: 'typeLike',
          format: ['PascalCase'],
        },
      ],
    },
  },

  {
    name: 'active in oxc',
    rules: {
      'no-self-assign': 'off',
      'no-unused-vars': 'off',
      'valid-params': 'off',
      'no-empty-object-type': 'off',
    },
  },

  {
    rules: {
      'prefer-destructuring': [
        'error',
        {
          VariableDeclarator: {
            array: false,
            object: true,
          },
          AssignmentExpression: {
            array: false,
            object: true,
          },
        },
        {
          enforceForRenamedProperties: false,
        },
      ],
    },
  },
  ...oxlint.buildFromOxlintConfigFile('./.oxlintrc.json'),

  eslintConfigPrettier,
)
