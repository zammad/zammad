// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export interface TooltipModifiers {
  /**
   * Only show the tooltip when the target's content is actually truncated
   */
  truncate?: boolean
  /**
   * Treat the tooltip as *supportive* information rather than
   * the element's accessible name.
   *
   * By default the directive writes the message to `aria-label`, which becomes
   * (or overrides) the element's accessible name. With this modifier the
   * message is written to `aria-description` instead, so screen readers
   * announce it *in addition to* the accessible name already provided by the
   * element or an ancestor.
   *
   * Use it when the element already has an accessible name and a tooltip label
   * would be redundant or misleading
   */
  supportive?: boolean
}
