// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, type Ref } from 'vue'

import type { DateTimeContext } from '#shared/components/Form/fields/FieldDate/types.ts'
import { usePickerModel } from '#shared/components/Form/fields/FieldDate/usePickerModel.ts'

type RangeValue = string | (string | null)[] | null

const setup = (context: Partial<DateTimeContext> = {}, initial: RangeValue = null) => {
  const stored = ref<RangeValue>(initial)
  const localValue = computed({
    get: () => stored.value,
    set: (value) => {
      stored.value = value
    },
  })
  const model = usePickerModel(ref(context) as unknown as Ref<DateTimeContext>, localValue)

  return { stored, ...model }
}

describe('usePickerModel', () => {
  it('drops a half-selected range when partialRange is false', () => {
    const { stored, pickerModel } = setup({ partialRange: false })

    pickerModel.value = ['2021-04-14', null]

    expect(stored.value).toBeNull()
  })

  it('commits a half-selected range when partialRange is not false', () => {
    const { stored, pickerModel } = setup()

    pickerModel.value = ['2021-04-14', null]

    expect(stored.value).toEqual(['2021-04-14', null])
  })

  it('commits a complete range', () => {
    const { stored, pickerModel } = setup({ partialRange: false })

    pickerModel.value = ['2021-04-14', '2021-04-28']

    expect(stored.value).toEqual(['2021-04-14', '2021-04-28'])
  })
})
