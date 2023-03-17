// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitConfig } from '@formkit/core'
import { inject } from 'vue'

const useFormKitConfig = () => {
  return inject(Symbol.for('FormKitConfig')) as FormKitConfig
}

export default useFormKitConfig
