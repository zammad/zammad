// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { shallowRef } from 'vue'

export const useIndicator = () => {
  const isIntersecting = shallowRef(false)

  return { isIntersecting }
}
