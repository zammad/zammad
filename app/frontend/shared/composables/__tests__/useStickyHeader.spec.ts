// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import type { Ref } from 'vue'
import { ref } from 'vue'
import { useStickyHeader } from '../useStickyHeader'

const fixedHeaderStyle = {
  left: '0',
  position: 'fixed',
  right: '0',
  top: '0',
  transition: 'transform 0.3s ease-in-out',
  zIndex: 9,
}

test('can pass down custom element', () => {
  const element = ref()
  const { headerElement } = useStickyHeader([], element)
  expect(headerElement).toBe(element)
})

test('reevaluates styles when dependencies change', async () => {
  const div = document.createElement('div')
  Object.defineProperty(div, 'clientHeight', { value: 100 })
  const element = ref(div) as Ref<HTMLElement>
  const dependency = ref(0)
  const { stickyStyles } = useStickyHeader([dependency], element)
  expect(stickyStyles.value).toEqual({})
  dependency.value = 1
  await flushPromises()
  expect(stickyStyles.value).toEqual({
    body: {
      marginTop: '100px',
    },
    header: {
      ...fixedHeaderStyle,
      transform: 'translateY(0px)',
    },
  })
})
