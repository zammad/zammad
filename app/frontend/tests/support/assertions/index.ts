// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable @typescript-eslint/no-empty-interface */

import type { ToBeAvatarOptions } from './toBeAvatarElement.ts'

export { default as toBeAvatarElement } from './toBeAvatarElement.ts'
export { default as toHaveClasses } from './toHaveClasses.ts'
export { default as toHaveImagePreview } from './toHaveImagePreview.ts'
export { default as toHaveCurrentUrl } from './toHaveCurrentUrl.ts'
export { default as toBeDescribedBy } from './toBeDescribedBy.ts'

interface CustomMatchers<R = unknown> {
  toBeAvatarElement(options?: ToBeAvatarOptions): R
  toHaveClasses(classes?: string[]): R
  toHaveImagePreview(content: string): R
  toHaveCurrentUrl(url: `/${string}`): R
  toBeDescribedBy(text: string): R
}

declare module 'vitest' {
  // eslint-disable-next-line @typescript-eslint/no-empty-object-type
  interface Assertion<T = any> extends CustomMatchers<T> {}
}
