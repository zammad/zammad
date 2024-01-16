// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { inject } from 'vue'
import type { SystemSetupManual } from '../types/setup-manual.ts'

export const SYSTEM_SETUP_MANUAL_SYMBOL = Symbol('SystemSetupManual')

export const useSystemSetupManual = () => {
  return inject(SYSTEM_SETUP_MANUAL_SYMBOL) as SystemSetupManual
}
