// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener } from '@vueuse/core'
import { useRouter } from 'vue-router'

import { isStandalone } from '#shared/utils/pwa.ts'

import { useBaseUrl } from './useBaseUrl.ts'

const useHtmlLinks = (urlPrefix: '/desktop' | '/mobile') => {
  const { baseUrl } = useBaseUrl()
  const router = useRouter()

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
    try {
      const url = new URL(link.href)

      if (
        url.origin === window.location.origin ||
        url.origin === baseUrl.value
      ) {
        const redirectRoute = getRedirectRoute(url)
        if (redirectRoute) {
          event.preventDefault()
          return openLink(link.target, redirectRoute)
        }
      }

      if (link.hasAttribute('external')) return

      if (!link.target) {
        event.preventDefault()
        window.open(link.href)
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

    link.href = `${baseUrl.value}${urlPrefix}/users/${userId}`
  }

  const setupLinksHandlers = (element: HTMLDivElement) => {
    element.querySelectorAll('a').forEach((link) => {
      if ('__handled' in link) return
      Object.defineProperty(link, '__handled', { value: true })
      patchUserMentionLinks(link)

      useEventListener(link, 'click', (event) => handleLinkClick(link, event))
    })
  }

  return {
    setupLinksHandlers,
  }
}

export { useHtmlLinks }
