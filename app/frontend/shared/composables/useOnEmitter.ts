// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { onScopeDispose, getCurrentScope } from 'vue'

import emitter, { type Events } from '#shared/utils/emitter.ts'

export const useOnEmitter = <K extends keyof Events>(
  name: K,
  callback: (payload: Events[K]) => void,
) => {
  emitter.on(name, callback)

  if (getCurrentScope()) {
    onScopeDispose(() => {
      emitter.off(name, callback)
    })
  }
}
