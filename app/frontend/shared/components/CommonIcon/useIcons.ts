// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useRawHTMLIcon } from './useRawHTMLIcon.ts'

const renameIcons = (icons: [string, { default: string }][]) => {
  const iconsMap: [string, string][] = []
  for (const [icon, svg] of icons) {
    const name = icon.match(/assets\/([\w-/]+)\.svg$/)
    if (!name) throw new Error(`Icon name not found for ${icon}`)
    const iconName = name[1].replace(/\//, '-')
    iconsMap.push([iconName, svg.default])
  }
  return iconsMap
}

let iconsSymbols: [string, string][] = []
let iconsContent: Record<string, string> = {}
let iconsAliasesMap: Record<string, string> = {}

export const provideIcons = (
  globImports: [string, { default: string }][],
  aliases: Record<string, string>,
) => {
  iconsSymbols = renameIcons(globImports)
  iconsContent = {}
  iconsAliasesMap = aliases
  for (const [name] of iconsSymbols) {
    const htmlIcon = useRawHTMLIcon({ name, size: 'base' })
    iconsContent[name] = htmlIcon
  }
  return {
    icons: iconsContent,
    symbols: iconsSymbols,
  }
}

export const useIcons = () => {
  return {
    icons: iconsContent,
    symbols: iconsSymbols,
    aliases: iconsAliasesMap,
  }
}
