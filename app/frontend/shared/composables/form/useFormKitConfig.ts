// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { inject } from 'vue'

import type { FormKitConfig } from '@formkit/core'

const useFormKitConfig = () => {
  return inject(Symbol.for('FormKitConfig')) as FormKitConfig
}

export default useFormKitConfig
