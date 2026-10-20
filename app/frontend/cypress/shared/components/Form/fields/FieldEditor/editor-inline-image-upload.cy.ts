// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'

import { mockApolloClient, mountComponent } from '#cy/utils.ts'

import { claimInlineImages } from '#shared/components/Form/fields/FieldEditor/features/image-handler/inlineImageUploads.ts'
import { TextModuleSuggestionsDocument } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.api.ts'
import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { FormUploadCacheAddDocument } from '#shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.api.ts'
import Form from '#shared/components/Form/Form.vue'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { dataURLToBlob } from '#shared/utils/files.ts'

import { EDITOR_IMAGE, mountEditor } from './utils.ts'

const PNG_DATA_URL =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='

const uploadedFiles = (id: number) => [
  {
    __typename: 'StoredFile',
    id: `gid://zammad/Store/${id}`,
    name: 'example.png',
    size: 12393,
    type: 'image/png',
  },
]

const mockUploads = (options: { copyDelay?: number; copyFailures?: number } = {}) => {
  const client = mockApolloClient()

  const addHandler = cy.stub().callsFake(async () => ({
    data: {
      formUploadCacheAdd: {
        __typename: 'FormUploadCacheAddPayload',
        uploadedFiles: uploadedFiles(42),
      },
    },
  }))

  let copyFailures = options.copyFailures || 0

  const copyHandler = cy.stub().callsFake(async () => {
    if (options.copyDelay) await new Promise((resolve) => setTimeout(resolve, options.copyDelay))

    if (copyFailures > 0) {
      copyFailures -= 1
      return { errors: [{ message: 'Temporary failure' }] }
    }

    return {
      data: {
        formUploadCacheAdd: {
          __typename: 'FormUploadCacheAddPayload',
          uploadedFiles: uploadedFiles(43),
        },
      },
    }
  })

  client.setRequestHandler(FormUploadCacheAddDocument, (variables) =>
    variables.files[0]?.attachmentId ? copyHandler(variables) : addHandler(variables),
  )

  cy.intercept('GET', '/api/v1/attachments/*', { fixture: 'example.png' })
  cy.intercept('GET', '/api/v1/ticket_attachment/**', { fixture: 'example.png' })

  return { addHandler, copyHandler, client }
}

const setEditorValue = (value: string) => cy.then(() => getNode('editor')?.input(value))

// The editor is mounted without a form, its images are claimed for the form id `undefined`.
const insertedHere = (value: string) => {
  claimInlineImages(undefined, value)
  return value
}

// Claims live as long as the browser tab, so every example uses its own image.
const quotedImage = (storeId: number) =>
  `<p><img src="/api/v1/ticket_attachment/1/2/${storeId}?view=inline"></p>`

describe('inline image upload', () => {
  it('does not upload images already in the upload cache', () => {
    const { addHandler, copyHandler } = mockUploads()

    mountEditor({ value: insertedHere('<p><img src="/api/v1/attachments/42"></p>') })

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/42')

    // Uploads start asynchronously, give them a chance to (wrongly) happen.
    cy.wait(300)

    cy.wrap(addHandler).should('not.have.been.called')
    cy.wrap(copyHandler).should('not.have.been.called')
  })

  it('copies quoted ticket attachment images into the upload cache', () => {
    const { addHandler, copyHandler } = mockUploads()

    mountEditor({ value: insertedHere(quotedImage(3)) })

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')

    cy.wrap(copyHandler).should('have.been.calledOnce')
    cy.wrap(copyHandler)
      .its('firstCall.args.0.files.0')
      .should('deep.equal', { attachmentId: 'gid://zammad/Store/3', inline: true })
    cy.wrap(addHandler).should('not.have.been.called')
  })

  it('leaves images alone which were inserted by another browser tab', () => {
    const { addHandler, copyHandler } = mockUploads()

    mountEditor({ value: quotedImage(4) })

    cy.findByRole('textbox')
      .find(EDITOR_IMAGE)
      .should('have.attr', 'src', '/api/v1/ticket_attachment/1/2/4?view=inline')

    cy.wait(300)

    cy.wrap(copyHandler).should('not.have.been.called')
    cy.wrap(addHandler).should('not.have.been.called')
    cy.findByText('Uploading…').should('not.exist')
  })

  it('uploads data URL images', () => {
    const { addHandler } = mockUploads()

    mountEditor({ value: insertedHere(`<p><img src="${PNG_DATA_URL}"></p>`) })

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/42')

    cy.wrap(addHandler).should('have.been.calledOnce')
    cy.wrap(addHandler)
      .its('firstCall.args.0.files.0')
      .should('include', { content: PNG_DATA_URL, type: 'image/png', inline: true })
  })

  it('shows a failure overlay for file URL images', () => {
    const { addHandler } = mockUploads()

    mountEditor({ value: insertedHere('<p><img src="file:///tmp/image.png"></p>') })

    cy.findByText('Failed to upload.').should('exist')
    cy.wrap(addHandler).should('not.have.been.called')
  })

  it('shows a source restriction overlay when an external image cannot be fetched', () => {
    const { addHandler } = mockUploads()

    cy.intercept('GET', 'https://example.com/image.png', { forceNetworkError: true })

    mountEditor({ value: insertedHere('<p><img src="https://example.com/image.png"></p>') })

    cy.findByText('Inserting image not possible due to source restrictions').should('exist')
    cy.wrap(addHandler).should('not.have.been.called')
  })

  it('does not upload an image uploading in another editor', () => {
    const { addHandler } = mockUploads()

    mountEditor({ value: '<p><img src="blob:http://localhost/some-upload"></p>' })

    cy.findByText('Uploading…').should('exist')

    cy.wait(300)

    cy.wrap(addHandler).should('not.have.been.called')
  })

  it('sizes the placeholder of an image uploading in another editor by its known size', () => {
    mockUploads()

    mountEditor({
      value: '<p><img src="blob:http://localhost/some-upload" width="300" height="150"></p>',
    })

    cy.findByText('Uploading…')
      .parent()
      .should(($placeholder) => {
        expect($placeholder.outerWidth()).to.eq(300)
        expect($placeholder.outerHeight()).to.eq(150)
      })
  })

  it('shows a default sized placeholder for an image of unknown size uploading in another editor', () => {
    mockUploads()

    mountEditor({ value: '<p><img src="blob:http://localhost/some-upload"></p>' })

    cy.findByText('Uploading…')
      .parent()
      .should(($placeholder) => {
        expect($placeholder.outerWidth()).to.be.at.least(160)
        expect($placeholder.outerHeight()).to.be.at.least(96)
      })
  })

  it('copies an image once when the content is written again during the copy', () => {
    const { copyHandler } = mockUploads({ copyDelay: 500 })
    const value = insertedHere(quotedImage(5))

    mountEditor({ value })

    cy.findByRole('textbox').find(EDITOR_IMAGE)

    setEditorValue(`<p>Reply</p>${value}`)
    setEditorValue(`<p>Reply again</p>${value}`)

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')

    cy.wrap(copyHandler).should('have.been.calledOnce')
  })

  it('copies an image once when the signature is added during the copy', () => {
    const { copyHandler } = mockUploads({ copyDelay: 500 })

    mountEditor({
      value: insertedHere(
        '<p></p><blockquote type="cite" data-marker="signature-before"><img src="/api/v1/ticket_attachment/1/2/6?view=inline"></blockquote>',
      ),
    })

    cy.findByRole('textbox').find(EDITOR_IMAGE)

    cy.then(() => {
      const context = getNode('editor')?.context as unknown as Required<FieldEditorContext>

      context.addSignature({ renderedBody: '<p>Signature</p>', internalId: 1 })
    })

    cy.findByRole('textbox').should('contain.text', 'Signature')
    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')

    cy.wrap(copyHandler).should('have.been.calledOnce')
  })

  it('uses the finished copy when the original content is written again', () => {
    const { copyHandler } = mockUploads()
    const value = insertedHere(quotedImage(7))

    mountEditor({ value })

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')

    setEditorValue(`<p>Reply</p>${value}`)

    cy.findByRole('textbox').should('contain.text', 'Reply')
    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')

    cy.wrap(copyHandler).should('have.been.calledOnce')
  })

  it('uses the finished copy when the image is inserted again', () => {
    const { copyHandler } = mockUploads()
    const value = insertedHere(quotedImage(12))

    mountEditor({ value })

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')

    cy.then(() => insertedHere(value))
    setEditorValue(`<p>Reply</p>${value}`)

    cy.findByRole('textbox').should('contain.text', 'Reply')
    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')

    cy.wait(300)
    cy.wrap(copyHandler).should('have.been.calledOnce')
  })

  it('releases the object URL of an inserted file after its upload', () => {
    mockUploads()

    const src = URL.createObjectURL(dataURLToBlob(PNG_DATA_URL))
    cy.spy(URL, 'revokeObjectURL').as('revokeObjectURL')

    mountEditor({ value: `<p><img src="${src}" content="${PNG_DATA_URL}"></p>` })

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/42')
    cy.get('@revokeObjectURL').should('have.been.calledWith', src)
  })

  it('uploads the images of an inserted text module', () => {
    const { addHandler, client } = mockUploads()

    client.setRequestHandler(TextModuleSuggestionsDocument, async () => ({
      data: {
        textModuleSuggestions: [
          {
            __typename: 'TextModule',
            id: convertToGraphQLId('TextModule', '1'),
            name: 'logo',
            keywords: null,
            // Another image than in the other examples, an uploaded one would be reused.
            renderedContent:
              '<p>Our logo: <img src="data:image/gif;base64,R0lGODlhAQABAAAAACw="></p>',
          },
        ],
      },
    }))

    mountEditor({}, ['ticket.agent'])

    cy.findByRole('textbox').type('::logo')
    cy.findByTestId('mention-text').findByText('logo').click()

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/42')
    cy.wrap(addHandler).should('have.been.calledOnce')
  })

  it('blocks the submit of a form mounted again during an upload', () => {
    mockUploads({ copyDelay: 1500 })

    const formId = 'remount-form'
    const value = quotedImage(13)

    claimInlineImages(formId, value)

    const mountForm = () =>
      mountComponent(Form, {
        props: {
          id: formId,
          formId,
          schema: [{ name: 'editor', type: 'editor' }],
          initialValues: { editor: value },
        },
      })

    const isUploadProcessing = () =>
      !!getNodeByName(formId, 'editor')?.root?.context?.state.uploadProcessing

    mountForm()
    cy.findByRole('textbox').find(EDITOR_IMAGE)

    mountForm()

    cy.wrap(null).should(() => expect(isUploadProcessing()).to.equal(true))

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')
    cy.wrap(null).should(() => expect(isUploadProcessing()).to.equal(false))
  })

  it('retries a failed image only when it is inserted again', () => {
    const { copyHandler } = mockUploads({ copyFailures: 1 })
    const value = insertedHere(quotedImage(8))

    mountEditor({ value })

    cy.findByText('Failed to upload.').should('exist')

    setEditorValue(`<p>Reply</p>${value}`)

    cy.findByRole('textbox').should('contain.text', 'Reply')
    cy.findByText('Failed to upload.').should('exist')
    cy.wrap(copyHandler).should('have.been.calledOnce')

    setEditorValue('<p>Reply</p>')
    cy.findByRole('textbox').find(EDITOR_IMAGE).should('not.exist')

    cy.then(() => insertedHere(value))
    setEditorValue(`<p>Reply</p>${value}`)

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')
    cy.wrap(copyHandler).should('have.been.calledTwice')
  })

  it('writes the copied address back to the field after a synchronous outside write', () => {
    mockUploads()
    const value = insertedHere(quotedImage(9))

    mountEditor({ value })

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')

    cy.then(() => getNode('editor')?.input(value, false))

    cy.wrap(null).should(() => {
      expect(getNode('editor')?.value).to.include('/api/v1/attachments/43')
    })
  })

  it('continues a running copy in a remounted editor', () => {
    const { copyHandler } = mockUploads({ copyDelay: 500 })
    const value = insertedHere(quotedImage(10))

    mountEditor({ value })
    cy.findByRole('textbox').find(EDITOR_IMAGE)

    mountEditor({ value })

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')
    cy.wrap(copyHandler).should('have.been.calledOnce')
  })

  it('forgets its images when the form is reset', () => {
    const { copyHandler } = mockUploads()
    const value = insertedHere(quotedImage(11))

    mountEditor({ value })

    cy.findByRole('textbox').find(EDITOR_IMAGE).should('have.attr', 'src', '/api/v1/attachments/43')

    cy.then(() => getNode('editor')?.reset())
    setEditorValue(value)

    cy.findByRole('textbox')
      .find(EDITOR_IMAGE)
      .should('have.attr', 'src', '/api/v1/ticket_attachment/1/2/11?view=inline')

    cy.wait(300)
    cy.wrap(copyHandler).should('have.been.calledOnce')
  })
})
