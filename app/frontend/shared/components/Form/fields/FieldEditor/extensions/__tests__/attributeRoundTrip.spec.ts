// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import { Editor } from '@tiptap/vue-3'

import Image from '../Image.ts'

// tiptap drops every attribute its schema does not declare, so loading a stored body into the
//   editor and reading it back is lossy for anything the extensions do not know about. The cid of
//   an inline image is the only record of which file it is, and losing it deletes that file on the
//   next save.
const roundTrip = (html: string) => {
  const editor = new Editor({
    extensions: [Document, Paragraph, Text, Image],
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
})
