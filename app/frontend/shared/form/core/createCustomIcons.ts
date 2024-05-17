// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { invert } from 'lodash-es'

import { useIcons } from '#shared/components/CommonIcon/useIcons.ts'

const createCustomIcons = (): Record<string, string> => {
  const { icons: customIcons, aliases: customIconAliases } = useIcons()
  const reversedCustomIconAliases = invert(customIconAliases)

  return Object.keys(customIcons).reduce(
    (icons: Record<string, string>, name) => {
      const alias = reversedCustomIconAliases[name]
      icons[alias || name] = customIcons[name]

      return icons
    },
    {},
  )
}

export default createCustomIcons
