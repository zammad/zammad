// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'
import { renderComponent } from '@tests/support/components'
import { i18n } from '@shared/i18n'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue' // TODO: switch to shared component example

describe('i18n', () => {
  it('starts with empty state', () => {
    expect(i18n.t('unknown string')).toBe('unknown string')
    expect(i18n.t('yes')).toBe('yes')
  })

  it('translates known strings', () => {
    const map = new Map([
      ['yes', 'ja'],
      ['Hello world!', 'Hallo Welt!'],
      ['The second component.', 'Die zweite Komponente.'],
      [
        'String with 3 placeholders: %s %s %s',
        'Zeichenkette mit 3 Platzhaltern: %s %s %s',
      ],
      ['FORMAT_DATE', 'dd/mm/yyyy'],
      ['FORMAT_DATETIME', 'dd/mm/yyyy HH:MM:SS'],
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

  it('translates dates', () => {
    expect(i18n.date('2021-04-09T10:11:12Z')).toBe('09/04/2021')
    expect(i18n.dateTime('2021-04-09T10:11:12Z')).toBe('09/04/2021 10:11:12')
    expect(i18n.relativeDateTime(new Date().toISOString())).toBe('just now')
  })

  it('updates (reactive) translations automatically', async () => {
    const { container } = renderComponent(CommonSectionMenu, {
      props: {
        headerLabel: 'Hello world!',
      },
      slots: {
        default: 'Example Content',
      },
      global: {
        mocks: {
          i18n,
        },
      },
    })

    expect(container).toHaveTextContent('Hallo Welt!')
    i18n.setTranslationMap(new Map())
    await nextTick()
    expect(container).toHaveTextContent('Hello world!')
  })
})
