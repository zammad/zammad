// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { defineComponent, ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { useTicketArticleCountChange } from '../useTicketArticleCountChange.ts'

const onChange = vi.fn()

const articleCount = ref<Maybe<number> | undefined>(1)

const mountComposable = () => {
  const TestComponent = defineComponent({
    setup() {
      useTicketArticleCountChange(articleCount, onChange)

      return () => null
    },
  })

  return renderComponent(TestComponent)
}

describe('useTicketArticleCountChange', () => {
  beforeEach(() => {
    onChange.mockClear()
    articleCount.value = 1
  })

  it('calls back when the count changes', async () => {
    mountComposable()

    articleCount.value = 2
    await flushPromises()

    expect(onChange).toHaveBeenCalledTimes(1)
  })

  it('stays quiet while the count is unchanged', async () => {
    mountComposable()

    articleCount.value = 1
    await flushPromises()

    expect(onChange).not.toHaveBeenCalled()
  })

  // A ticket that has not arrived yet reads as `undefined`, and the count itself is nullable.
  it('stays quiet for a first reading', async () => {
    articleCount.value = undefined

    mountComposable()

    articleCount.value = 3
    await flushPromises()

    expect(onChange).not.toHaveBeenCalled()

    articleCount.value = 4
    await flushPromises()

    expect(onChange).toHaveBeenCalledTimes(1)
  })
})
