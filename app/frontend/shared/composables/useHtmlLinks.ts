// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useRouter } from 'vue-router'

import { useApplicationStore } from '#shared/stores/application.ts'
import { isStandalone } from '#shared/utils/pwa.ts'

const useHtmlLinks = (urlPrefix: '/desktop' | '/mobile') => {
  const router = useRouter()
  const application = useApplicationStore()

  const getRedirectRoute = (url: URL): string | undefined => {
    if (url.pathname.startsWith(urlPrefix)) {
      return url.href.slice(`${url.origin}${urlPrefix}`.length)
    }

    const route = router.resolve(`/${url.hash.slice(1)}${url.search}`)
    if (route.name !== 'Error') {
      return route.fullPath
    }
  }

  const openLink = (target: string, path: string) => {
    // keep links inside PWA inside the app
    if (!isStandalone() && target && target !== '_self') {
      window.open(`${urlPrefix}${path}`, target)
    } else {
      router.push(path)
    }
  }

  const handleLinkClick = (link: HTMLAnchorElement, event: Event) => {
    const fqdnOrigin = `${window.location.protocol}//${application.config.fqdn}${
      window.location.port ? `:${window.location.port}` : ''
    }`
    try {
      const url = new URL(link.href)
      if (url.origin === window.location.origin || url.origin === fqdnOrigin) {
        const redirectRoute = getRedirectRoute(url)
        if (redirectRoute) {
          openLink(link.target, redirectRoute)
          event.preventDefault()
        }
      }
    } catch {
      // skip
    }
  }

  // user links has fqdn in its href, but if it changes the link becomes invalid
  // to bypass that we replace the href with the correct one
  const patchUserMentionLinks = (link: HTMLAnchorElement) => {
    const userId = link.dataset.mentionUserId

    if (!userId) return

    link.href = `${window.location.origin}${urlPrefix}/users/${userId}`
  }

  const setupLinksHandlers = (element: HTMLDivElement) => {
    element.querySelectorAll('a').forEach((link) => {
      if ('__handled' in link) return
      Object.defineProperty(link, '__handled', { value: true })
      patchUserMentionLinks(link)
      link.addEventListener('click', (event) => handleLinkClick(link, event))
    })
  }

  return {
    setupLinksHandlers,
  }
}

export { useHtmlLinks }
