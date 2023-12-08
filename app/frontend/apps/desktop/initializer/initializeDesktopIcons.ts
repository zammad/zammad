// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { injectSvgIcons } from '#shared/components/CommonIcon/injectIcons.ts'
import { provideIcons } from '#shared/components/CommonIcon/useIcons.ts'
import iconsAliases from './desktopIconsAliasesMap.ts'

const iconsSymbolsList = Object.entries(
  import.meta.glob<{ default: string }>('./assets/*.svg', {
    eager: true,
    as: 'symbol',
  }),
)

export const initializeDesktopIcons = () => {
  const { symbols } = provideIcons(iconsSymbolsList, iconsAliases)
  injectSvgIcons(symbols)
}
