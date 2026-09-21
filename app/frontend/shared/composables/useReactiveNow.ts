// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useIntervalFn, useNow } from '@vueuse/core'

const reactiveNow = useNow({
  scheduler: (cb) => useIntervalFn(cb, 1000),
})

export const useReactiveNow = () => reactiveNow
