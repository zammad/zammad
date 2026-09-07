// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

const UNSAFE_URL_SCHEMES = new Set(['javascript', 'vbscript'])

// Neutralize urls whose scheme would execute script when used as an href
//   (javascript:, vbscript:), otherwise return the url unchanged. Everything else
//   — relative, http(s), mailto, tel, data:, blob: — is kept, so this stays usable
//   for general links (e.g. data-URI attachment downloads).
export const safeUrl = (url?: string | null): string => {
  if (!url) return ''

  // Strip control characters (incl. tab/newline) that browsers ignore when
  //   parsing a scheme, e.g. `java\tscript:` would otherwise slip through.
  const stripped = Array.from(url)
    .filter((char) => {
      const code = char.charCodeAt(0)
      return code > 0x1f && code !== 0x7f
    })
    .join('')

  const scheme = stripped.match(/^\s*([a-z][a-z0-9+.-]*):/i)
  if (scheme && UNSAFE_URL_SCHEMES.has(scheme[1].toLowerCase())) return ''

  return stripped
}
