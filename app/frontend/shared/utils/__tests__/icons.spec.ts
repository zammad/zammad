// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getIconByContentType } from '../icons.ts'

describe('getIconByContentType', () => {
  it('returns correct icon for known content types', () => {
    expect(getIconByContentType('image/jpeg')).toBe('photos')
    expect(getIconByContentType('audio/mpeg')).toBe('audio')
    expect(getIconByContentType('video/mp4; charset=UTF-8; method=REQUEST')).toBe('video')
  })

  it('returns fallback icon for unknown content types', () => {
    expect(getIconByContentType('application/octet-stream')).toBe('file')
    expect(getIconByContentType('; charset=utf-8')).toBe('file')
    expect(getIconByContentType('')).toBe('file')
  })
})
