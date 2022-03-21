// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormAppSpecificTheme,
  FormThemeClasses,
  FormThemeExtension,
} from '@common/types/form'
import commonClasses from '@common/form/theme/global'
import { generateClasses } from '@formkit/tailwindcss'
import type {
  ImportGlobEagerOutput,
  ImportGlobEagerDefault,
} from '@common/types/utils'
import { extend } from '@formkit/utils'

const extensionsModules: ImportGlobEagerOutput<FormThemeExtension> =
  import.meta.globEager('../theme/global/extensions/*.ts')

const getExtensionsFromModules = (
  extensionsModules: ImportGlobEagerOutput<FormThemeExtension>,
) => {
  const extensions: FormThemeExtension[] = []

  Object.values(extensionsModules).forEach(
    (module: ImportGlobEagerDefault<FormThemeExtension>) => {
      const extension = module.default

      extensions.push(extension)
    },
  )

  return extensions
}
const createTailwindClasses = (additionalTheme: FormAppSpecificTheme = {}) => {
  const themeExtensions: FormThemeExtension[] = [
    ...getExtensionsFromModules(extensionsModules),
  ]

  if (additionalTheme.coreClasses) {
    themeExtensions.push(additionalTheme.coreClasses)
  }

  if (additionalTheme.extensions) {
    themeExtensions.push(
      ...getExtensionsFromModules(additionalTheme.extensions),
    )
  }

  let classes = commonClasses

  themeExtensions.forEach((extension) => {
    const newClasses = extension(classes)
    classes = extend(classes, newClasses) as FormThemeClasses
  })

  return generateClasses(classes)
}

export default createTailwindClasses
