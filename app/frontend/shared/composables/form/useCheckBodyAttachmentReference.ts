// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FileUploaded } from '#shared/components/Form/fields/FieldFile/types.ts'
import { i18n } from '#shared/i18n.ts'

import { useConfirmation } from '../useConfirmation.ts'

const referenceMatchwords = [
  __('Attachment'),
  __('attachment'),
  __('Attached'),
  __('attached'),
  __('Enclosed'),
  __('enclosed'),
  __('Enclosure'),
  __('enclosure'),
]

const removeQuotingFromBody = (body: string) => {
  const parser = new DOMParser()
  const document = parser.parseFromString(body, 'text/html')

  // Select all blockquote elements
  const foundBlockquotes = document.querySelectorAll('blockquote')
  foundBlockquotes.forEach((blockquote) => blockquote.remove())

  // Return the modified HTML content as a string.
  return document.body.innerHTML
}

const bodyAttachmentReferenceMatchwordExists = (body: string) => {
  const cleanBody = removeQuotingFromBody(body)

  return referenceMatchwords.some((word) => {
    let findWord = new RegExp(word, 'i')

    if (findWord.test(cleanBody)) return true

    // Translate the word in the user locale.
    findWord = new RegExp(i18n.t(word), 'i')

    return findWord.test(cleanBody)
  })
}

export const useCheckBodyAttachmentReference = () => {
  const { waitForConfirmation } = useConfirmation()

  const missingBodyAttachmentReference = (
    body: string,
    files?: FileUploaded[],
  ) => {
    if (!body) return false
    if (files && files.length > 0) return false

    return bodyAttachmentReferenceMatchwordExists(body)
  }

  const bodyAttachmentReferenceConfirmation = async () => {
    const confirmed = await waitForConfirmation(
      __('Did you plan to include attachments with this message?'),
      {
        buttonLabel: __('Yes, add attachments now'),
        cancelLabel: __('No, thanks'),
      },
    )

    return confirmed
  }

  return {
    missingBodyAttachmentReference,
    bodyAttachmentReferenceConfirmation,
  }
}
