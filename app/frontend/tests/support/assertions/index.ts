// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable @typescript-eslint/no-empty-interface */

import type { ToBeAvatarOptions } from './toBeAvatarElement.ts'

export { default as toBeAvatarElement } from './toBeAvatarElement.ts'
export { default as toHaveClasses } from './toHaveClasses.ts'
export { default as toHaveImagePreview } from './toHaveImagePreview.ts'

interface CustomMatchers<R = unknown> {
  toBeAvatarElement(options?: ToBeAvatarOptions): R
  toHaveClasses(classes?: string[]): R
  toHaveImagePreview(content: string): R
}

declare module 'vitest' {
  interface Assertion<T = any> extends CustomMatchers<T> {}
  interface AsymmetricMatchersContaining extends CustomMatchers {}
}
