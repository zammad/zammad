// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { type MaybeRef, toValue } from 'vue'

import type { FormFieldValue } from '#shared/components/Form/types.ts'

export const domFrom = (html: string, document_ = document) => {
  const dom = document_.createElement('div')
  dom.innerHTML = html
  return dom
}

export const removeSignatureFromBody = (input: FormFieldValue, placeholder: boolean = false) => {
  if (!input || typeof input !== 'string') {
    return input
  }

  const dom = domFrom(input)

  dom.querySelectorAll('div[data-signature-placeholder]').forEach((elem) => elem.remove())

  dom.querySelectorAll('div[data-signature]').forEach((elem) => {
    if (placeholder) {
      elem.replaceWith(domFrom('<div data-signature-placeholder="true"></div>'))
    } else {
      elem.remove()
    }
  })

  return dom.innerHTML
}

/**
 * Queries all images in the container and waits for them to load.
 * */
export const waitForImagesToLoad = async (container: MaybeRef) => {
  const inlineImages: HTMLImageElement[] = toValue(container).querySelectorAll('img')

  if (inlineImages.length > 0) {
    return Promise.allSettled<null>(
      Array.from(inlineImages).map((image) => {
        return new Promise((resolve, reject) => {
          const cleanup = () => {
            image.onload = null
            image.onerror = null
          }

          const handleLoad = () => {
            cleanup()
            resolve(null)
          }

          const handleError = () => {
            cleanup()
            reject()
          }

          image.onload = handleLoad
          image.onerror = handleError
        })
      }),
    )
  }

  return Promise.allSettled<null>([])
}
