// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const openExternalLink = (url: string, target: string = '_blank') => {
  const link = document.createElement('a')
  link.href = url
  link.target = target
  link.click()
  link.remove()
}

export default openExternalLink
