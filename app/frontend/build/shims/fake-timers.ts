// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

// Browser shim for @sinonjs/fake-timers in non-test builds.
// If this ever executes, it's a mistake — throw loudly to catch it.
export function install() {
  throw new Error('@sinonjs/fake-timers should not be loaded in browser builds')
}
export default { install }
