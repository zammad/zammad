// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// Add global __() method for marking translatable strings.

// eslint-disable-next-line no-underscore-dangle
window.__ = function __(source: string): string {
  return source
}

// Add 'export' to treat this as a JS module.
export {}
