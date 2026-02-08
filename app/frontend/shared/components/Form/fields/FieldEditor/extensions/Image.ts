// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Image from '@tiptap/extension-image'
import { VueNodeViewRenderer } from '@tiptap/vue-3'

import ImageHandler from '#shared/components/Form/fields/FieldEditor/features/image-handler/ImageHandler.vue'
import { dataURLToBlob } from '#shared/utils/files.ts'

const getAttributeFromElement = (element: Element, attr: 'width' | 'height') => {
  const htmlElement = element as HTMLElement
  return htmlElement.style[attr]
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
