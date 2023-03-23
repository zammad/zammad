// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ToBeAvatarOptions } from './toBeAvatarElement'

export { default as toBeAvatarElement } from './toBeAvatarElement'
export { default as toHaveClasses } from './toHaveClasses'
export { default as toHaveImagePreview } from './toHaveImagePreview'

interface CustomMatchers<R = unknown> {
  toBeAvatarElement(options?: ToBeAvatarOptions): R
  toHaveClasses(classes?: string[]): R
  toHaveImagePreview(content: string): R
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Vi {
    // eslint-disable-next-line @typescript-eslint/no-empty-interface
    interface Assertion extends CustomMatchers {}
    // eslint-disable-next-line @typescript-eslint/no-empty-interface
    interface AsymmetricMatchersContaining extends CustomMatchers {}
  }
}
