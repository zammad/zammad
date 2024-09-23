// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldValue } from '#shared/components/Form/types.ts'

export const domFrom = (html: string, document_ = document) => {
  const dom = document_.createElement('div')
  dom.innerHTML = html
  return dom
}

export const removeSignatureFromBody = (input: FormFieldValue) => {
  if (!input || typeof input !== 'string') {
    return input
  }

  const dom = domFrom(input)

  dom
    .querySelectorAll('div[data-signature="true"]')
    .forEach((elem) => elem.remove())

  return dom.innerHTML
}
