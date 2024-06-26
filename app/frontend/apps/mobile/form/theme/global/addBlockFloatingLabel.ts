// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Classes } from '#shared/form/plugins/utils.ts'
import { clean, extendClasses } from '#shared/form/plugins/utils.ts'

import { addStaticFloatingLabel } from './addStaticFloatingLabel.ts'

export const addBlockFloatingLabel = (classes: Classes = {}): Classes => {
  return addStaticFloatingLabel(
    extendClasses(classes, {
      outer: 'floating-input',
      label: clean(
        `formkit-populated:-translate-y-[0.4rem] formkit-populated:scale-80 formkit-populated:opacity-75 formkit-populated:text-xs text-base`,
      ),
    }),
  )
}
