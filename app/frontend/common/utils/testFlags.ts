// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { Mutex } from 'async-mutex'

class TestFlags {
  private mutex = new Mutex()

  private flags: Map<string, boolean> = new Map()

  get(flag: string, skipClearing = false): boolean {
    if (!VITE_TEST_MODE) return false
    const flagValue = !!this.flags.get(flag)
    if (!skipClearing) this.clear(flag)
    return flagValue
  }

  async set(flag: string): Promise<void> {
    if (!VITE_TEST_MODE) return
    await this.mutex.runExclusive(() => {
      this.flags.set(flag, true)
    })
  }

  async clear(flag: string): Promise<void> {
    if (!VITE_TEST_MODE) return
    await this.mutex.runExclusive(() => {
      this.flags.delete(flag)
    })
  }
}

const testFlags = new TestFlags()

declare global {
  interface Window {
    testFlags: TestFlags
  }
}

if (VITE_TEST_MODE) {
  // Register globally for access from Capybara/Selenium.
  window.testFlags = testFlags
}

export default testFlags
