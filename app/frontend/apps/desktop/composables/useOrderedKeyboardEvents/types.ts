// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

/**
 * @see https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key
 */
export enum KeyboardKey {
  Escape = 'escape',
  Shift = 'shift',
  Enter = 'enter',
  Control = 'control',
  Alt = 'alt',
}

export interface OrderKeyHandlerConfig {
  handler: () => void
  key: string
  beforeHandlerRuns?: () => boolean | Promise<boolean> | void
}
