// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Image, { type ImageOptions } from '@tiptap/extension-image'
import { VueNodeViewRenderer } from '@tiptap/vue-3'

import ImageHandler from '#shared/components/Form/fields/FieldEditor/features/image-handler/ImageHandler.vue'
import { createInlineImageUploads } from '#shared/components/Form/fields/FieldEditor/features/image-handler/inlineImageUploads.ts'
import { dataURLToBlob, type ImageFileData } from '#shared/utils/files.ts'

import type { Command } from '@tiptap/core'

const getAttributeFromElement = (element: Element, attr: 'width' | 'height') => {
  const htmlElement = element as HTMLElement

  // Prefer the plain HTML attribute — that's what our own renderHTML emits and what
  // ImageHandler.vue expects (unitless numeric string, or the '100%'/'auto' defaults).
  // Fall back to the inline style for externally authored/pasted HTML (e.g. an email's
  // style="width:400px" or style="width:300pt") that never had the plain attribute set.
  // Use || rather than ?? so an empty attribute (width="") also falls back to the style.
  const value = htmlElement.getAttribute(attr) || htmlElement.style[attr]
  if (!value) return null

  // Percentage values are valid as-is (e.g. "100%").
  if (value.endsWith('%')) return value

  // Strip any CSS unit suffix and return the numeric part. This handles px, pt, em,
  // rem, cm, etc. Return null (so the schema default applies) if the result is not finite.
  const numeric = parseFloat(value)
  return Number.isFinite(numeric) ? String(numeric) : null
}

const insertImages =
  (toSrc: (image: ImageFileData) => string) =>
  (images: ImageFileData[]): Command =>
  ({ chain }) =>
    chain()
      .focus()
      .insertContent([
        ...images.map((image) => ({
          type: 'image',
          attrs: {
            src: toSrc(image),
            alt: image.name,
            type: image.type,
            content: image.content,
          },
        })),
        { type: 'paragraph' },
      ])
      .run()

const ZammadImage = Image.extend<ImageOptions>({
  addProseMirrorPlugins() {
    return [...(this.parent?.() || []), createInlineImageUploads(this.editor)]
  },

  addAttributes() {
    return {
      ...this.parent?.(),

      width: {
        default: '100%',
        // The defaults stand for the natural size, written out they would stretch the image.
        renderHTML: (attributes) =>
          attributes.width && attributes.width !== '100%' ? { width: attributes.width } : {},
        parseHTML: (element) => getAttributeFromElement(element, 'width'),
      },

      height: {
        default: 'auto',
        renderHTML: (attributes) =>
          attributes.height && attributes.height !== 'auto' ? { height: attributes.height } : {},
        parseHTML: (element) => getAttributeFromElement(element, 'height'),
      },

      // An inline image of a stored record travels as a `cid:` reference, which the backend swaps
      // for an attachment URL when it hands the body out - moving the cid into this attribute
      // (HasRichText.insert_urls). On the way back HtmlSanitizer::CidToSrc turns it into
      // `src="cid:…"` again. tiptap drops any attribute the schema does not declare, and a saved
      // body that references no cid makes has_rich_text_cleanup_unused_attachments delete every
      // inline image of the record - so this has to be parsed and rendered, not just tolerated.
      cid: {
        default: null,
        parseHTML: (element) => element.getAttribute('cid'),
        renderHTML: (attributes) => (attributes.cid ? { cid: attributes.cid } : {}),
      },

      isDraggable: {
        default: true,
        renderHTML: () => {
          return {}
        },
      },

      type: {
        default: null,
        renderHTML: () => ({}),
      },

      style: {
        default: null,
        renderHTML: () => ({}),
      },

      content: {
        default: null,
        renderHTML: () => ({}),
      },
    }
  },

  addNodeView() {
    return VueNodeViewRenderer(ImageHandler)
  },
  addCommands() {
    return {
      setImages: insertImages((image) => URL.createObjectURL(dataURLToBlob(image.content))),
    }
  },
}).configure({
  inline: true,
  allowBase64: true,
})

export default ZammadImage

// For HTML read where Zammad's attachments cannot be loaded, like the chat widget on a foreign site:
//   the image is not uploaded and leaves the editor as the data URL it was pasted as. An image of
//   pasted HTML is only kept when it is embedded too, so no foreign server learns who reads it.
export const EmbeddedImage = ZammadImage.extend({
  addProseMirrorPlugins() {
    return []
  },

  parseHTML() {
    return [{ tag: 'img[src^="data:image/"]' }]
  },

  // No preview URL that would have to be revoked: nothing is uploaded, the data URL stays the source.
  addCommands() {
    return {
      setImages: insertImages((image) => image.content),
    }
  },

  addAttributes() {
    return {
      ...this.parent?.(),

      // The widget shows a message as it is, in a bubble with no rule for images of its own. The
      //   height follows the width, so a resized image keeps its ratio in a narrower bubble.
      style: {
        default: null,
        renderHTML: () => ({ style: 'max-width: 100%; height: auto;' }),
      },
    }
  },
})
