// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import CommonHighlightedText from '../CommonHighlightedText.vue'

describe('CommonHighlightedText', () => {
  it('marks the highlighted segments and leaves the others plain', () => {
    const view = renderComponent(CommonHighlightedText, {
      props: {
        segments: [
          { text: 'Connect the ', highlight: false },
          { text: 'printer', highlight: true },
          { text: ' via USB.', highlight: false },
        ],
      },
    })

    const marks = view.container.querySelectorAll('mark')

    expect(marks).toHaveLength(1)
    expect(marks[0]).toHaveTextContent('printer')
    expect(view.container).toHaveTextContent('Connect the printer via USB.')
  })

  it('renders search-engine markup as text rather than as HTML', () => {
    const view = renderComponent(CommonHighlightedText, {
      props: {
        segments: [{ text: '<em>printer</em>', highlight: true }],
      },
    })

    expect(view.container.querySelector('em')).not.toBeInTheDocument()
    expect(view.container.querySelector('mark')).toHaveTextContent('<em>printer</em>')
  })

  it('renders nothing for no segments', () => {
    const view = renderComponent(CommonHighlightedText, { props: { segments: [] } })

    expect(view.container).toHaveTextContent('')
  })
})
