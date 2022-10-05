// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// Add global __() method for marking translatable strings.

const getGlobalThis = () => {
  if (typeof globalThis !== 'undefined') return globalThis
  return window
}

// eslint-disable-next-line no-underscore-dangle
getGlobalThis().__ = (source) => source

// Add 'export' to treat this as a JS module.
export {}
