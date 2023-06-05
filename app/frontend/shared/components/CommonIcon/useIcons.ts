// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useRawHTMLIcon } from './composable.ts'

const renameIcons = (icons: [string, { default: string }][]) => {
  const iconsMap: [string, string][] = []
  for (const [icon, svg] of icons) {
    const name = icon.match(/([\w-]+\/[\w-]+)\.svg/)
    if (!name) throw new Error(`Icon name not found for ${icon}`)
    const iconName = name[1].replace(/\//, '-')
    iconsMap.push([iconName, svg.default])
  }
  return iconsMap
}

const iconsSymbolsList = Object.entries(
  import.meta.glob<{ default: string }>('./assets/**/*.svg', {
    eager: true,
    as: 'symbol',
  }),
)

const iconsSymbols = renameIcons(iconsSymbolsList)
const iconsContent: Record<string, string> = {}
for (const [name] of iconsSymbols) {
  const htmlIcon = useRawHTMLIcon({ name, size: 'base' })
  iconsContent[name] = htmlIcon
}

export const useIcons = () => {
  return {
    icons: iconsContent,
    symbols: iconsSymbols,
  }
}
