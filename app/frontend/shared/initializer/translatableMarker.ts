// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// Add global __() method for marking translatable strings.

const getGlobalThis = () => {
  if (typeof globalThis !== 'undefined') return globalThis
  return window
}

getGlobalThis().__ = (source) => source

// Add 'export' to treat this as a JS module.
export {}
