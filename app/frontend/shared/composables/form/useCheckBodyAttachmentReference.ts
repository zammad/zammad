// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { FileUploaded } from '#shared/components/Form/fields/FieldFile/types.ts'
import { i18n } from '#shared/i18n.ts'
import { domFrom } from '#shared/utils/dom.ts'

import { useConfirmation } from '../useConfirmation.ts'

const referenceMatchwords = __('attachment,attached,enclosed,enclosure')

const removeQuotingFromBody = (body: string) => {
  const dom = domFrom(body)

  // Remove blockquotes, signatures and images
  // To not detect matchwords which are not part of the user-written article
  dom
    .querySelectorAll('blockquote, img, div[data-signature="true"]')
    .forEach((elem) => elem.remove())

  // Return the modified HTML content as a string.
  return dom.innerHTML
}

const bodyAttachmentReferenceMatchwordExists = (body: string) => {
  const cleanBody = removeQuotingFromBody(body)

  const matchwords = referenceMatchwords.split(',')
  const translatedMatchwords = i18n.t(referenceMatchwords).split(',')

  return matchwords.concat(translatedMatchwords).some((word) => {
    const findWord = new RegExp(`\\b${word}\\b`, 'i')
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

    // In case the user clicked outside the confirmation dialog or closed it in another way,
    //  we would like to abort the submit of the related form.
    return confirmed === undefined ? true : confirmed
  }

  return {
    missingBodyAttachmentReference,
    bodyAttachmentReferenceConfirmation,
  }
}
