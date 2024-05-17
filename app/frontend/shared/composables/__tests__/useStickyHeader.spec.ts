// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'

import { useStickyHeader } from '../useStickyHeader.ts'

import type { Ref } from 'vue'

const fixedHeaderStyle = {
  left: '0',
  position: 'fixed',
  right: '0',
  top: '0',
  transition: 'transform 0.3s ease-in-out',
  zIndex: 9,
}

test('can pass down custom html element', () => {
  const header = document.createElement('header')
  const element = ref(header)
  const { headerElement } = useStickyHeader([], element)
  expect(headerElement.value).toBe(header)
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
