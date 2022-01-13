// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { VueWrapper } from '@vue/test-utils'
import { ComponentPublicInstance } from 'vue'

// Workaround to get the vm from the wrapper without type complaining.
const getVMFromWrapper = (
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  wrapper: VueWrapper<ComponentPublicInstance<any>>,
) => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return wrapper.vm as any
}

export default getVMFromWrapper
