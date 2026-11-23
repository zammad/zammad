// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { configSymbol } from '@formkit/vue'
import { inject } from 'vue'

import type { FormKitRootConfig } from '@formkit/core'

const useFormKitConfig = () => {
  return inject(configSymbol) as FormKitRootConfig
}

export default useFormKitConfig
