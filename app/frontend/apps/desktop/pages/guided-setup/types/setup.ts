// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { BoxSizes } from '#desktop/components/layout/types.ts'

export interface SystemSetup {
  setBoxSize?: (boxSize: BoxSizes) => void
  setHideFooter?: (hideFooter: boolean) => void
  setTitle: (title: string) => void
}
