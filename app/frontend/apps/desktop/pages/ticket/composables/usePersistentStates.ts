// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { reactive } from 'vue'

import type { ObjectLike } from '#shared/types/utils.ts'

export const usePersistentStates = () => {
  const persistentStates = reactive<ObjectLike>({})

  return { persistentStates }
}
