// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { convertFileList } from '#shared/utils/files.ts'

export const populateEditorNewLines = (htmlContent: string): string => {
  const body = document.createElement('div')
  body.innerHTML = htmlContent
  // prosemirror always adds a visible linebreak inside an empty paragraph,
  // but it doesn't return it inside a schema, so we need to add it manually
  body.querySelectorAll('p').forEach((p) => {
    p.removeAttribute('data-marker')
    if (
      p.childNodes.length === 0 ||
      p.lastChild?.nodeType !== Node.TEXT_NODE ||
      p.textContent?.endsWith('\n')
    ) {
      p.appendChild(document.createElement('br'))
    }
  })
  return body.innerHTML
}

export const convertInlineImages = (
  inlineImages: FileList | File[],
  editorElement: HTMLElement,
) => {
  return convertFileList(inlineImages, {
    compress: true,
    onCompress: () => {
      const editorWidth = editorElement.clientWidth
      const maxWidth = editorWidth > 1000 ? editorWidth : 1000
      return {
        x: maxWidth,
        scale: 2,
        type: 'image/jpeg',
      }
    },
  })
}
