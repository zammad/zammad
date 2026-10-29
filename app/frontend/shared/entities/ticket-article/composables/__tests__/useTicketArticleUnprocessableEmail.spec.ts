// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'

import { useTicketArticleUnprocessableEmail } from '../useTicketArticleUnprocessableEmail.ts'

const rawEmailAttachment = {
  internalId: 11,
  name: 'some-name.eml',
  type: 'message/rfc822',
  preferences: { email_unprocessable: 'raw' },
}

const processingLogAttachment = {
  internalId: 12,
  name: 'other-name.txt',
  type: 'text/plain',
  preferences: { email_unprocessable: 'log' },
}

const unmarkedAttachments = [
  {
    internalId: 13,
    name: 'unprocessable_email.eml',
    type: 'message/rfc822',
    preferences: {},
  },
  {
    internalId: 14,
    name: 'processing_log.txt',
    type: 'text/plain',
    preferences: null,
  },
]

describe('useTicketArticleUnprocessableEmail', () => {
  beforeEach(() => {
    mockApplicationConfig({ api_path: '/api' })
  })

  it('detects a flagged article and picks its attachments by marker', () => {
    const article = createDummyArticle({
      preferences: { email_unprocessable: true },
      attachmentsWithoutInline: [
        ...unmarkedAttachments,
        processingLogAttachment,
        rawEmailAttachment,
      ],
    })

    const { isUnprocessableEmail, rawEmail, processingLog } =
      useTicketArticleUnprocessableEmail(article)

    expect(isUnprocessableEmail.value).toBe(true)

    expect(rawEmail.value).toMatchObject({
      internalId: 11,
      name: 'some-name.eml',
      downloadUrl: '/api/attachments/11?disposition=attachment',
    })

    expect(processingLog.value).toMatchObject({
      internalId: 12,
      name: 'other-name.txt',
      downloadUrl: '/api/attachments/12?disposition=attachment',
    })
  })

  it('ignores attachments of an article without the flag', () => {
    const article = createDummyArticle({
      attachmentsWithoutInline: [rawEmailAttachment, processingLogAttachment],
    })

    const { isUnprocessableEmail, rawEmail, processingLog } =
      useTicketArticleUnprocessableEmail(article)

    expect(isUnprocessableEmail.value).toBe(false)
    expect(rawEmail.value).toBeUndefined()
    expect(processingLog.value).toBeUndefined()
  })

  it('does not pick attachments by filename', () => {
    const article = createDummyArticle({
      preferences: { email_unprocessable: true },
      attachmentsWithoutInline: unmarkedAttachments,
    })

    const { isUnprocessableEmail, rawEmail, processingLog } =
      useTicketArticleUnprocessableEmail(article)

    expect(isUnprocessableEmail.value).toBe(true)
    expect(rawEmail.value).toBeUndefined()
    expect(processingLog.value).toBeUndefined()
  })

  it('follows a changing article', () => {
    const article = ref<ReturnType<typeof createDummyArticle> | undefined>()

    const { isUnprocessableEmail, rawEmail } = useTicketArticleUnprocessableEmail(article)

    expect(isUnprocessableEmail.value).toBe(false)

    article.value = createDummyArticle({
      preferences: { email_unprocessable: true },
      attachmentsWithoutInline: [rawEmailAttachment],
    })

    expect(isUnprocessableEmail.value).toBe(true)
    expect(rawEmail.value?.internalId).toBe(11)
  })
})
