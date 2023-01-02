// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const csrfTokenMetaElement: Maybe<HTMLMetaElement> = document.querySelector(
  'meta[name="csrf-token"]',
)

const initialCsrfToken = csrfTokenMetaElement
  ? csrfTokenMetaElement.getAttribute('content')
  : null
let csrfToken: Maybe<string> = null

export const setCSRFToken = (newCSRFToken: string) => {
  csrfToken = newCSRFToken
}

export const getCSRFToken = (): Maybe<string> => {
  return csrfToken || initialCsrfToken
}
