// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Image from '@tiptap/extension-image'
import { VueNodeViewRenderer } from '@tiptap/vue-3'

import ImageHandler from '#shared/components/Form/fields/FieldEditor/features/image-handler/ImageHandler.vue'
import { dataURLToBlob } from '#shared/utils/files.ts'

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

export default Image.extend({
  addAttributes() {
    return {
      ...this.parent?.(),

      width: {
        default: '100%',
        renderHTML: (attributes) => {
          return { width: attributes.width }
        },
        parseHTML: (element) => getAttributeFromElement(element, 'width'),
      },

      height: {
        default: 'auto',
        renderHTML: (attributes) => {
          return {
            height: attributes.height,
          }
        },
        parseHTML: (element) => getAttributeFromElement(element, 'height'),
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
      setImages:
        (attributes) =>
        ({ chain }) => {
          return chain()
            .focus()
            .insertContent([
              ...attributes.map((image) => {
                return {
                  type: 'image',
                  attrs: {
                    src: URL.createObjectURL(dataURLToBlob(image.content)),
                    alt: image.name,
                    type: image.type,
                    content: image.content,
                  },
                }
              }),
              {
                type: 'paragraph',
              },
            ])
            .run()
        },
    }
  },
}).configure({
  inline: true,
  allowBase64: true,
})
