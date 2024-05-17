// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { inject, provide } from 'vue'

import type { ImportSource } from '../types/setup-import.ts'

export const IMPORT_SOURCE = Symbol('ImportSource')

export const useImportSource = () => {
  return inject(IMPORT_SOURCE) as ImportSource
}

export const provideImportSource = (importSource: ImportSource) => {
  provide(IMPORT_SOURCE, importSource)
}
