// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { i18n } from '#shared/i18n.ts'

import CommonlTranslateRenderer from '../CommonTranslateRenderer.vue'

const populateTranslationMap = () => {
  const map = new Map([
    [
      'A example with an %s which can be inside a %s.',
      'Ein Beispiel mit einem %s, das in einer %s enthalten sein kann.',
    ],
    ['translation', 'Übersetzung'],
    ['FORMAT_DATE', 'dd/mm/yyyy'],
    ['FORMAT_DATETIME', 'dd/mm/yyyy HH:MM:SS'],
  ])

  i18n.setTranslationMap(map)
}

describe('CommonlTranslateRenderer.vue', () => {
  beforeEach(() => {
    populateTranslationMap()
  })

  it('renders link in given source string', () => {
    const view = renderComponent(CommonlTranslateRenderer, {
      props: {
        source: 'A example with an %s which can be inside a %s.',
        placeholders: [
          {
            type: 'link',
            props: {
              link: 'https://www.zammad.org',
              class: 'custom-class',
            },
            content: 'Link',
          },
          i18n.t('translation'),
        ],
      },
      router: true,
    })

    const link = view.getByTestId('common-link')
    expect(link).toHaveTextContent('Link')
    expect(link).toHaveClass('custom-class')
    expect(link).toHaveAttribute('href', 'https://www.zammad.org')
  })

  it('renders a common label in given source string', () => {
    const view = renderComponent(CommonlTranslateRenderer, {
      props: {
        source: 'A example with an %s which can be inside a %s.',
        placeholders: [
          {
            type: 'label',
            props: {
              class: 'custom-class',
            },
            content: 'Label',
          },
          i18n.t('translation'),
        ],
      },
      router: true,
    })

    console.log('view:', view.html())

    const label = view.getByTestId('common-label')

    expect(label).toHaveTextContent('Label')
    expect(label).toHaveClass('custom-class')
  })
})
