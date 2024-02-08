// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { BoxSizes } from '#desktop/components/layout/types.ts'

export interface SystemSetupManual {
  setBoxSize: (boxSize: BoxSizes) => void
  setHideFooter: (hideFooter: boolean) => void
  setTitle: (title: string) => void
}

export interface SystemInformationData {
  organization: string
  logo: string
  url: string
  localeDefault: string
  timezoneDefault: string
}
