// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Document from '@tiptap/extension-document'
import { ListItem } from '@tiptap/extension-list'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import { Editor } from '@tiptap/vue-3'

import Image from '../Image.ts'
import OrderedList from '../OrderedList.ts'

import type { Extensions } from '@tiptap/core'

// tiptap drops every attribute its schema does not declare, so loading a stored body into the
//   editor and reading it back is lossy for anything the extensions do not know about. The cid of
//   an inline image is the only record of which file it is, and losing it deletes that file on the
//   next save.
const roundTrip = (html: string, extensions: Extensions = [Image]) => {
  const editor = new Editor({
    extensions: [Document, Paragraph, Text, ...extensions],
    content: html,
  })

  const result = editor.getHTML()
  editor.destroy()

  return result
}

describe('editor attribute round trip', () => {
  // HasRichText.insert_urls hands the body out with the cid moved into an attribute;
  //   HtmlSanitizer::CidToSrc turns it back into `src="cid:…"` on save. Without the cid the saved
  //   body references nothing, and has_rich_text_cleanup_unused_attachments deletes the file.
  it('keeps the cid of an inline image', () => {
    const result = roundTrip('<p><img src="/api/v1/attachments/42" cid="foo@zammad.com"></p>')

    expect(result).toContain('cid="foo@zammad.com"')
    expect(result).toContain('src="/api/v1/attachments/42"')
  })

  // A `start` of one is the one number tiptap leaves out of its own markup, and the one number a
  //   list counting down cannot do without: without it the list counts from its item count instead.
  it('keeps the number a list counting down was given, even where it is a one', () => {
    const items = '<li><p>One</p></li><li><p>Zero</p></li><li><p>Minus one</p></li>'

    const result = roundTrip(`<ol reversed="" start="1">${items}</ol>`, [ListItem, OrderedList])

    expect(result).toBe(`<ol reversed="" start="1">${items}</ol>`)
  })

  // Without the attribute the quoted list counts up from the offset restored by
  //   restoreOrderedListStart(), turning the 3 and 2 of the original into 3 and 4.
  it('keeps a list counting down', () => {
    const result = roundTrip('<ol reversed="" start="3"><li><p>Three</p></li></ol>', [
      ListItem,
      OrderedList,
    ])

    expect(result).toBe('<ol reversed="" start="3"><li><p>Three</p></li></ol>')
  })
})
