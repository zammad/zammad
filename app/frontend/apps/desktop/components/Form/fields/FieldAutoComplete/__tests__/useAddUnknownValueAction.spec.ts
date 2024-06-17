// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import {
  emailFilterValueValidator,
  phoneFilterValueValidator,
  useAddUnknownValueAction,
} from '../useAddUnknownValueAction.ts'

import type { AutoCompleteOptionValueDictionary } from '../types.ts'

const testOptions: AutoCompleteOptionValueDictionary = {
  1: {
    value: 1,
    label: 'Item 1',
  },
  2: {
    value: 2,
    label: 'Item 2',
  },
  3: {
    value: 3,
    label: 'Item 3',
  },
}

const testEmailAddress = 'nicole.braun@zammad.org'
const testPhoneNumber = '+490123456789'

describe('emailFilterValueValidator', () => {
  it('returns true on valid email address', async () => {
    expect(emailFilterValueValidator(testEmailAddress)).toBe(true)
  })

  it('returns false on invalid email address', async () => {
    expect(emailFilterValueValidator('foobar')).toBe(false)
  })
})

describe('phoneFilterValueValidator', () => {
  it('returns true on valid phone number', async () => {
    expect(phoneFilterValueValidator(testPhoneNumber)).toBe(true)
  })

  it('returns false on invalid phone number', async () => {
    expect(phoneFilterValueValidator('Zammad2024')).toBe(false)
  })
})

describe('useAddUnknownValueAction', () => {
  it('provides default action item and search interaction event handler', async () => {
    const { actions, onSearchInteractionUpdate } = useAddUnknownValueAction()

    const testSelectOption = vi.fn()
    const testClearFilter = vi.fn()

    onSearchInteractionUpdate(
      testEmailAddress,
      testOptions,
      testSelectOption,
      testClearFilter,
    )

    expect(actions.value).toEqual([
      expect.objectContaining({
        icon: 'plus-square-fill',
        key: 'addUnknownValue',
        label: 'add new email address',
      }),
    ])

    actions.value[0].onClick(true)

    expect(testSelectOption).toHaveBeenCalledWith(
      {
        value: testEmailAddress,
        label: testEmailAddress,
      },
      true,
    )

    expect(testClearFilter).toHaveBeenCalledOnce()
  })

  it('provides keydown filter event handler', async () => {
    const { actions, onKeydownFilterInput } = useAddUnknownValueAction()

    const testSelectOption = vi.fn()
    const testClearFilter = vi.fn()

    onKeydownFilterInput(
      new KeyboardEvent('keydown', { key: 'Enter' }),
      testEmailAddress,
      testOptions,
      testSelectOption,
      testClearFilter,
    )

    expect(actions.value).toEqual([])

    expect(testSelectOption).toHaveBeenCalledWith(
      {
        value: testEmailAddress,
        label: testEmailAddress,
      },
      true,
    )

    expect(testClearFilter).toHaveBeenCalledOnce()
  })

  it('supports providing custom action label', async () => {
    const testActionLabel = ref('foo')

    const { actions, onSearchInteractionUpdate } =
      useAddUnknownValueAction(testActionLabel)

    const testSelectOption = vi.fn()
    const testClearFilter = vi.fn()

    onSearchInteractionUpdate(
      testEmailAddress,
      testOptions,
      testSelectOption,
      testClearFilter,
    )

    expect(actions.value).toEqual([
      expect.objectContaining({
        label: 'foo',
      }),
    ])

    testActionLabel.value = 'bar'

    onSearchInteractionUpdate(
      testEmailAddress,
      testOptions,
      testSelectOption,
      testClearFilter,
    )

    expect(actions.value).toEqual([
      expect.objectContaining({
        label: 'bar',
      }),
    ])
  })

  it('supports providing custom validator', async () => {
    const testActionLabel = ref(
      'the answer to life the universe and everything',
    )

    const testFilterValueValidator = (filter: string) =>
      parseInt(filter, 10) === 42

    const { actions, onSearchInteractionUpdate } = useAddUnknownValueAction(
      testActionLabel,
      testFilterValueValidator,
    )

    onSearchInteractionUpdate('42', testOptions, vi.fn(), vi.fn())

    expect(actions.value).toHaveLength(1)

    onSearchInteractionUpdate('3', testOptions, vi.fn(), vi.fn())

    expect(actions.value).toHaveLength(0)
  })
})
