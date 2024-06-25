// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useCheckBodyAttachmentReference } from '../useCheckBodyAttachmentReference.ts'

describe('useCheckBodyAttachmentReference', () => {
  it('check for missing body attachment reference', () => {
    const { missingBodyAttachmentReference } = useCheckBodyAttachmentReference()

    expect(missingBodyAttachmentReference('I attached a file.')).toBeTruthy()
  })

  it('check for existing attachment and body reference', () => {
    const { missingBodyAttachmentReference } = useCheckBodyAttachmentReference()

    expect(
      missingBodyAttachmentReference('I attached a file.', [
        { id: '123', name: 'filename.png' },
      ]),
    ).toBeFalsy()
  })

  it('not attachment reference in body', () => {
    const { missingBodyAttachmentReference } = useCheckBodyAttachmentReference()

    expect(
      missingBodyAttachmentReference('I worked on the problem.'),
    ).toBeFalsy()
  })

  it('ignore attachment match words in quoted body parts', () => {
    const { missingBodyAttachmentReference } = useCheckBodyAttachmentReference()

    expect(
      missingBodyAttachmentReference(
        '<p>Yes I did already a first look.</p><blockquote type="cite" data-marker="signature-before"><p>I attached a file did you saw id?</p></blockquote>',
      ),
    ).toBeFalsy()
  })
})
