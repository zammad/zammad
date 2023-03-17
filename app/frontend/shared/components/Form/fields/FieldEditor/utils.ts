// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
