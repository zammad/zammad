// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { FormKitConfig } from '@formkit/core'
import { inject } from 'vue'

const useFormKitConfig = () => {
  return inject(Symbol.for('FormKitConfig')) as FormKitConfig
}

export default useFormKitConfig
