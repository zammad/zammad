// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module.exports = {
  // This option sets the URL for the jsdom environment. It is reflected in properties such as location.href.
  testURL: 'http://localhost',
  rootDir: '../../../',
  roots: ['app/frontend/tests'],
  moduleDirectories: ['node_modules', 'app/frontend'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/app/frontend/$1',
    '^@mobile/(.*)$': '<rootDir>/app/frontend/apps/mobile/$1',
    '^@common/(.*)$': '<rootDir>/app/frontend/common/$1',
    '^@tests/(.*)$': '<rootDir>/app/frontend/tests/$1',
    '\\.(jpg|jpeg|png|gif|eot|otf|webp|svg|ttf|woff|woff2|mp4|webm|wav|mp3|m4a|aac|oga)$':
      'jest-transform-stub',
    '^lodash-es$': 'lodash',
  },
  moduleFileExtensions: ['js', 'ts', 'json', 'vue'],
  preset: 'ts-jest',
  testMatch: ['**/?(*.)+(spec|test).+(ts|tsx)'],
  transform: {
    '^.+\\.(ts|tsx)$': 'ts-jest',
    '^.+\\.vue$': '@vue/vue3-jest',
  },
  testEnvironment: 'jsdom',
}
