// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { inject } from 'vue'

import type { SystemSetup } from '../types/setup.ts'

export const SYSTEM_SETUP_SYMBOL = Symbol('SystemSetup')

export const useSystemSetup = () => {
  return inject(SYSTEM_SETUP_SYMBOL) as SystemSetup
}
