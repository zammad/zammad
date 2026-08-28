// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Editor } from '@tiptap/core'
import type { Node as ProseMirrorNode } from '@tiptap/pm/model'

// Name of the toolbar tool that embeds a video. It writes a plain-text marker rather than a node of
//   its own, so it has no TipTap extension, and it is opted into per field — see
//   `optInExtensionNames`, whose `satisfies` check ties this name to the `meta` key a form declares
//   to switch the tool on.
export const VIDEO_EMBED_ACTION_NAME = 'videoEmbed'

// The provider keys are a contract with the backend: `VideoEmbed.lookup_provider` matches them
//   against `VideoEmbed::Backend.key`, so they must stay exactly these strings.
export type VideoProvider = 'youtube' | 'vimeo' | 'peertube' | 'mediacms'

// How a provider is spelled where an author is shown one, as opposed to the key it is stored under.
//   Doubles as the list of providers there is anything to show for: a marker naming one that is not
//   in here is one the server would not expand either.
export const VIDEO_PROVIDER_LABELS: Record<VideoProvider, string> = {
  youtube: 'YouTube',
  vimeo: 'Vimeo',
  peertube: 'PeerTube',
  mediacms: 'MediaCMS',
}

export interface VideoServer {
  name: string
  host: string
}

export interface DetectedVideo {
  provider: VideoProvider
  id: string
  // Only a self-hosted provider carries one; a built-in one lives at a fixed host.
  host?: string
}

// Built-in providers are recognized purely by their (fixed) URL.
//
// Mirrored one to one from the legacy popup (`popup_video.coffee`), unescaped dots included, so
//   that a URL either tool accepts is accepted by both.
const BUILT_IN_REGEXPS: Record<string, RegExp[]> = {
  youtube: [
    /youtube.com\/watch\?v=(\S[^:#?&/]+)/,
    /youtu.be\/(\S[^:#?&/]+)/,
    /youtube.com\/embed\/(\S[^:#?&/]+)/,
  ],
  vimeo: [/vimeo.com\/(\w+)/],
}

// Self-hosted providers can live on any (admin-approved) host, so the provider is determined by
//   matching the pasted URL's path/query; the host is taken from the URL itself and checked against
//   the configured server list separately.
const SELF_HOSTED_REGEXPS: Record<string, RegExp[]> = {
  peertube: [/\/w\/([\w-]+)/, /\/videos\/(?:watch|embed)\/([\w-]+)/],
  mediacms: [/[?&]m=([\w-]+)/],
}

// Asked of the object's own keys, never of the ones every object inherits: a marker naming
//   `constructor` or `toString` as its provider would otherwise be answered by `Object.prototype`.
const isSelfHosted = (provider: VideoProvider) => Object.hasOwn(SELF_HOSTED_REGEXPS, provider)

export const hostFromUrl = (input: string) => {
  // A pasted URL may well come without its scheme, which `URL` insists on.
  for (const candidate of [input, `https://${input}`]) {
    try {
      return new URL(candidate).host
    } catch {
      continue
    }
  }

  return undefined
}

const detectSelfHosted = (input: string): DetectedVideo | undefined => {
  const host = hostFromUrl(input)

  if (!host) return undefined

  for (const [provider, regexps] of Object.entries(SELF_HOSTED_REGEXPS)) {
    for (const regexp of regexps) {
      const result = input.match(regexp)

      if (result) return { provider: provider as VideoProvider, id: result[1], host }
    }
  }

  return undefined
}

export const detectVideo = (input?: string): DetectedVideo | undefined => {
  if (!input) return undefined

  for (const [provider, regexps] of Object.entries(BUILT_IN_REGEXPS)) {
    for (const regexp of regexps) {
      const result = input.match(regexp)

      if (result) return { provider: provider as VideoProvider, id: result[1] }
    }
  }

  return detectSelfHosted(input)
}

export const videoServerAllowed = (host: string, servers: VideoServer[]) =>
  servers.some((server) => server.host === host)

// A video is stored as a plain-text marker in the body, which the server turns into an iframe on
//   read (`KnowledgeBaseRichText.expand_video_widgets`). That splits on `,` and then on `:` with a
//   limit of two, so the keys must be literally `provider`, `host` and `id` — and the spacing stays
//   the one the legacy popup wrote, so both tools produce the same body.
export const videoWidgetMarker = ({ provider, id, host }: DetectedVideo) => {
  if (!host) return `( widget: video, provider: ${provider}, id: ${id} )`

  return `( widget: video, provider: ${provider}, host: ${host}, id: ${id} )`
}

/**
 * Parses a stored marker back into its parts, the counterpart of `videoWidgetMarker`. Anything the
 * server would not expand either — an unknown provider, a missing id, a self-hosted video without
 * its host — is no video, so that such a marker is left alone rather than presented as one.
 */
export const parseVideoWidgetMarker = (marker: string): DetectedVideo | undefined => {
  // The splitting the server does (`KnowledgeBaseRichText.expand_video_widgets`): on `,`, then on
  //   the first `:` only, so that a value carrying one of its own survives.
  const settings = Object.fromEntries(
    marker
      .slice(1, -1)
      .split(',')
      .map((pair) => {
        const separator = pair.indexOf(':')

        if (separator === -1) return [pair.trim(), '']

        return [pair.slice(0, separator).trim(), pair.slice(separator + 1).trim()]
      }),
  )

  if (settings.widget !== 'video') return undefined

  const provider = settings.provider as VideoProvider

  if (!Object.hasOwn(VIDEO_PROVIDER_LABELS, provider)) return undefined
  if (!settings.id) return undefined
  if (isSelfHosted(provider) && !settings.host) return undefined

  return {
    provider,
    id: settings.id,
    ...(settings.host ? { host: settings.host } : {}),
  }
}

const VIDEO_WIDGET_MARKER_PATTERN = /\(\s*widget:\s*video\W[^)]*\)/g

/** Ranges of every video marker in one text block, mapped back to document positions. */
const markerRangesInTextblock = (block: ProseMirrorNode, blockStart: number) => {
  // Position of every character of the block's text, so that a match in its text content can be
  //   mapped back to the document. Non-text inline nodes contribute nothing to the text but do take
  //   up a position, hence the walk rather than plain arithmetic.
  const positions: number[] = []
  let childPosition = blockStart

  block.forEach((child) => {
    if (child.isText) {
      for (let index = 0; index < (child.text?.length ?? 0); index += 1) {
        positions.push(childPosition + index)
      }
    }

    childPosition += child.nodeSize
  })

  return [...block.textContent.matchAll(VIDEO_WIDGET_MARKER_PATTERN)].map((match) => ({
    from: positions[match.index],
    to: positions[match.index + match[0].length - 1] + 1,
    marker: match[0],
  }))
}

/** Ranges of every video marker in the document, for the decoration that styles them. */
export const videoMarkerRanges = (doc: ProseMirrorNode) => {
  const ranges: ReturnType<typeof markerRangesInTextblock> = []

  doc.descendants((node, position) => {
    if (!node.isTextblock) return true

    // A text block's content starts one position after the block itself, and holds no block of its
    //   own, so there is nothing below it to descend into.
    ranges.push(...markerRangesInTextblock(node, position + 1))

    return false
  })

  return ranges
}

/**
 * Document range of the video at the given position, if any: what the whole of a video is, for the
 * keys and the rules that act on one rather than on the characters it is stored as.
 *
 * Only a marker that is shown as a video counts, the same ones the chips are drawn for. A marker
 * the server would not expand either is left as the plain text it is drawn as, so that it is
 * edited like any other text.
 */
export const videoMarkerRangeAt = (editor: Editor, position: number) => {
  const $position = editor.state.doc.resolve(position)
  const { parent } = $position

  if (!parent.isTextblock) return undefined

  return markerRangesInTextblock(parent, $position.start()).find(
    ({ from, to, marker }) => from <= position && position <= to && parseVideoWidgetMarker(marker),
  )
}

/**
 * Where an embedded video goes: a row holds one video and nothing else, so it takes the empty row
 * the caret sits in, or a row of its own under the row it sits in. Never the caret itself, which
 * would join the video to whatever that row already holds — its text, or another video.
 */
export const newVideoRowAt = (editor: Editor) => {
  const { doc, selection } = editor.state
  const $caret = doc.resolve(selection.from)

  // No caret in a row of text to go by, so the video goes at the end of the document.
  if (!$caret.parent.isTextblock) return doc.content.size

  const row = { from: $caret.before($caret.depth), to: $caret.after($caret.depth) }

  // An empty row is the video's to take, rather than being left standing above it.
  return $caret.parent.content.size ? row.to : row
}
