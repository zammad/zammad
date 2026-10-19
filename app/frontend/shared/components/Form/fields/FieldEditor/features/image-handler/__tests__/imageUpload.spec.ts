// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  mockFormUploadCacheAddMutation,
  waitForFormUploadCacheAddMutationCalls,
} from '#shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { copyInlineImages, getTicketAttachmentStoreId } from '../imageUpload.ts'

const uploadedFile = (id: number) => ({
  id: convertToGraphQLId('Store', id),
  name: `image-${id}.png`,
  size: 100,
  type: 'image/png',
})

describe('getTicketAttachmentStoreId', () => {
  it.each([
    ['/api/v1/ticket_attachment/1/2/3?view=inline', '3'],
    ['/api/v1/ticket_attachment/1/2/3', '3'],
    [`${window.location.origin}/api/v1/ticket_attachment/1/2/3`, '3'],
    ['https://example.com/api/v1/ticket_attachment/1/2/3', undefined],
    ['/api/v1/attachments/3', undefined],
    ['data:image/png;base64,AAAA', undefined],
  ])('returns the store id of %s', (src, expected) => {
    expect(getTicketAttachmentStoreId(src)).toBe(expected)
  })
})

describe('copyInlineImages', () => {
  it('adds copies of the attachments to the upload cache as inline images', async () => {
    mockFormUploadCacheAddMutation({
      formUploadCacheAdd: { uploadedFiles: [uploadedFile(11), uploadedFile(12)] },
    })

    await expect(copyInlineImages('form-id', ['3', '4'])).resolves.toEqual([
      '/api/v1/attachments/11',
      '/api/v1/attachments/12',
    ])

    const calls = await waitForFormUploadCacheAddMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      formId: 'form-id',
      files: [
        { attachmentId: convertToGraphQLId('Store', 3), inline: true },
        { attachmentId: convertToGraphQLId('Store', 4), inline: true },
      ],
    })
  })
})
