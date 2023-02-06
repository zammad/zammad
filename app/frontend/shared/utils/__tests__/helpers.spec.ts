// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { textToHtml } from '../helpers'

describe('textToHtml', () => {
  it('adds links to URL-like text', () => {
    const input = 'Some Text\n\nhttp://example.com'
    const output =
      '<div>Some Text</div><div><br></div><div><a href="http://example.com">http://example.com</a></div>'

    expect(textToHtml(input)).toBe(output)
  })

  it('escapes HTML-like text to make sure it is presented as-is', () => {
    const input = '<p>&It;div&gt;hello world&lt;/div&gt;</p>'
    const output =
      '<div>&lt;p&gt;&amp;It;div&amp;gt;hello world&amp;lt;/div&amp;gt;&lt;/p&gt;</div>'

    expect(textToHtml(input)).toBe(output)
  })
})
