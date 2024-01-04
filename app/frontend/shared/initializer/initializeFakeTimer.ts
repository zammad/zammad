// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { install, type InstalledClock } from '@sinonjs/fake-timers'

const useFakeTimers = (config: { now: Date }) => {
  const clock = install(config) as InstalledClock & { restore(): void }
  clock.restore = clock.uninstall
  return clock
}
// support old-style sinon.useFakeTimers instead of overriding a method for mobile tests
Reflect.set(globalThis, 'sinon', { useFakeTimers })
