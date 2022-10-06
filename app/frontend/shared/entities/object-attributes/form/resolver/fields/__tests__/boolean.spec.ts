// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { CheckboxVariant } from '@shared/components/Form/fields/FieldCheckbox'
import { FieldResolverBoolean } from '../boolean'

describe('FieldResolverBoolean', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverBoolean({
      dataType: 'boolean',
      name: 'correct',
      display: 'Correct?',
      dataOption: {
        options: { false: 'no', true: 'yes' },
      },
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Correct?',
      name: 'correct',
      props: {
        translations: {
          false: 'no',
          true: 'yes',
        },
        variant: CheckboxVariant.Switch,
      },
      type: 'checkbox',
    })
  })
})
