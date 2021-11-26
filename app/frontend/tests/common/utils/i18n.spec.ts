// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@common/utils/i18n'
import CommonHelloWorld from '@common/components/common/CommonHelloWorld.vue'
import { shallowMount } from '@vue/test-utils'
import { nextTick } from 'vue'

describe('i18n', () => {
  it('starts with empty state', () => {
    expect(i18n.t('unknown string')).toBe('unknown string')
    expect(i18n.t('yes')).toBe('yes')
  })

  it('translates known strings', () => {
    const map = new Map([
      ['yes', 'ja'],
      ['Hello world!', 'Hallo Welt!'],
      [
        'String with 3 placeholders: %s %s %s',
        'Zeichenkette mit 3 Platzhaltern: %s %s %s',
      ],
    ])

    i18n.setTranslationMap(map)
    expect(i18n.t('yes')).toBe('ja')
  })
  it('handles placeholders correctly', () => {
    // No arguments.
    expect(i18n.t('String with 3 placeholders: %s %s %s')).toBe(
      'Zeichenkette mit 3 Platzhaltern: %s %s %s',
    )
  })

  it('updates (reactive) translations automatically', async () => {
    expect.assertions(2)
    const msg = 'Hello world!'
    const wrapper = shallowMount(CommonHelloWorld, {
      props: { msg, show: true },
      global: {
        mocks: {
          i18n,
        },
      },
    })
    expect(wrapper.text()).toMatch('Hallo Welt!')
    i18n.setTranslationMap(new Map())
    await nextTick()
    expect(wrapper.text()).toMatch('Hello world!')
  })
})
