// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { claimInlineImages, getInlineImageUpload } from '../inlineImageUploads.ts'

describe('claimInlineImages', () => {
  it('claims images that still need to be uploaded or copied', () => {
    claimInlineImages(
      'claim-form',
      '<p><img src="/api/v1/ticket_attachment/1/2/3?view=inline&amp;x=1"><img src="https://example.com/a.png"><img src="data:image/png;base64,AAAA"></p>',
    )

    expect(
      getInlineImageUpload('claim-form', '/api/v1/ticket_attachment/1/2/3?view=inline&x=1'),
    ).toMatchObject({ status: 'claimed' })
    expect(getInlineImageUpload('claim-form', 'https://example.com/a.png')).toMatchObject({
      status: 'claimed',
    })
    expect(getInlineImageUpload('claim-form', 'data:image/png;base64,AAAA')).toMatchObject({
      status: 'claimed',
    })
  })

  it('does not claim images which are already uploaded or belong to another editor', () => {
    claimInlineImages(
      'claim-form-2',
      '<img src="/api/v1/attachments/5"><img src="blob:http://localhost/1"><img src="cid:image.1@example.com">',
    )

    expect(getInlineImageUpload('claim-form-2', '/api/v1/attachments/5')).toBeUndefined()
    expect(getInlineImageUpload('claim-form-2', 'blob:http://localhost/1')).toBeUndefined()
    expect(getInlineImageUpload('claim-form-2', 'cid:image.1@example.com')).toBeUndefined()
  })

  it('keeps the claims of each form apart', () => {
    claimInlineImages('claim-form-3', '<img src="https://example.com/b.png">')

    expect(getInlineImageUpload('claim-form-4', 'https://example.com/b.png')).toBeUndefined()
  })

  it('accepts an element', () => {
    const element = document.createElement('div')
    element.innerHTML = '<img src="https://example.com/c.png">'

    claimInlineImages('claim-form-5', element)

    expect(getInlineImageUpload('claim-form-5', 'https://example.com/c.png')).toMatchObject({
      status: 'claimed',
    })
  })
})
