// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { domFrom } from '../dom.ts'

describe('domFrom', () => {
  const input = '<div>test</div>'

  it('parses dom and returns exact string representation', () => {
    const dom = domFrom(input)

    expect(dom.innerHTML).toBe(input)
  })

  it('parses dom and returns matching structure', () => {
    const dom = domFrom(input)

    expect(dom).toBeInstanceOf(HTMLElement)
    expect(dom.childNodes.length).toBe(1)

    const firstNode = dom.childNodes[0]

    expect(firstNode.textContent).toBe('test')
    expect(firstNode.childNodes[0]).toBeInstanceOf(Text)
  })
})
