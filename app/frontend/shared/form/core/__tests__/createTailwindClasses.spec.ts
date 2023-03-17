// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import globalClasses from '@shared/form/theme/global'
import createTailwindClasses from '@shared/form/core/createTailwindClasses'
import type { FormThemeClasses } from '@shared/types/form'

vi.mock('@formkit/themes', () => {
  return {
    generateClasses: (classes: FormThemeClasses) => classes,
  }
})

describe('createTailwindClasses', () => {
  it('check that common classes will be returned', () => {
    const classes = createTailwindClasses() as unknown as FormThemeClasses

    expect(classes).toEqual(globalClasses)
  })

  it('check that app specific core classes can be used', () => {
    const customFieldClasses = {
      outer: 'custom-field-outer',
    }

    const classes = createTailwindClasses({
      coreClasses: () => {
        return {
          customField: customFieldClasses,
        }
      },
    }) as unknown as FormThemeClasses

    expect(classes.customField).toEqual(customFieldClasses)
  })

  it('extension modules can be used', () => {
    const customFieldClasses = {
      outer: 'custom-field-outer',
    }

    const classes = createTailwindClasses({
      extensions: {
        customField: {
          default: (classes: FormThemeClasses) => {
            return {
              global: {
                wrapper: `${classes.global.wrapper} custom-class`,
              },
              customField: customFieldClasses,
            }
          },
        },
      },
    }) as unknown as FormThemeClasses

    expect(classes.global.wrapper).toContain(
      'formkit-disabled:opacity-30 custom-class',
    )
    expect(classes.customField).toEqual(customFieldClasses)
  })
})
