// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { markup } from '../markup'

it('markup creates correct html', () => {
  expect(markup('||italic||')).toBe('<i>italic</i>')
  expect(markup('|bold|')).toBe('<b>bold</b>')
  expect(markup('_underline_')).toBe('<u>underline</u>')
  expect(markup('//strikethrough//')).toBe('<del>strikethrough</del>')
  expect(markup('§keyboard§')).toBe('<kbd>keyboard</kbd>')
  expect(markup('[link](https://zammad.org)')).toBe(
    '<a href="https://zammad.org" target="_blank">link</a>',
  )
})
