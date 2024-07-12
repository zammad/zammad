// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export const domFrom = (html: string, document_ = document) => {
  const dom = document_.createElement('div')
  dom.innerHTML = html
  return dom
}
