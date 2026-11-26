// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { MaybeRefOrGetter } from 'vue'

export interface CoveringOverlay {
  id: string
  element: MaybeRefOrGetter<HTMLElement | null | undefined>
  // Only the overlays of the page on screen show their backdrop, those of the pages kept alive in
  //   the background stay open without one.
  isShown: MaybeRefOrGetter<boolean>
  // The backdrop covers the whole application instead of the page, e.g. on small screens.
  coversApplication: MaybeRefOrGetter<boolean>
}
