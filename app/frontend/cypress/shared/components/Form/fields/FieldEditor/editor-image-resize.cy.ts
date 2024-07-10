// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '#cy/utils.ts'

import { FormUploadCacheAddDocument } from '#shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.api.ts'

import { mountEditor } from './utils.ts'

describe('resizing image within editor', () => {
  it('can be resized', { retries: 2 }, () => {
    const client = mockApolloClient()
    client.setRequestHandler(FormUploadCacheAddDocument, async () => ({
      data: {
        formUploadCacheAdd: {
          __typename: 'FormUploadCacheAddPayload',
          uploadedFiles: [
            {
              __typename: 'StoredFile',
              id: 'gid://zammad/Store/2062',
              name: 'file.png',
              size: 12393,
              type: 'image/png',
            },
          ],
        },
      },
    }))

    cy.intercept('GET', '/api/v1/attachments/2062', { fixture: 'example.png' })

    mountEditor()
    cy.findByRole('textbox').click()
    cy.findByTestId('action-bar')
      .findByLabelText('Add image')
      .click() // click inserts input into DOM
      .then(() => {
        cy.findByTestId('editor-image-input').selectFile(
          {
            contents: '.dev/cypress/fixtures/example.png',
            fileName: 'file.png',
            mimeType: 'image/png',
            lastModified: Date.now(),
          },
          { force: true },
        )
      })
    cy.findByRole('textbox').get('img:first').trigger('click')

    cy.get('.vdr-handle:last')
      .trigger('mousedown', { button: 0 })
      .trigger('mousemove', { pageX: 100, pageY: 100 })
      .trigger('mouseup', { button: 0 })
      .then(($item) => {
        cy.get('img').then(($img) => {
          const height = $img.height()
          const width = $img.width()
          expect(width).to.eq(83)
          expect(height).to.eq(83)
          return $item
        })
      })
      .trigger('mousedown', { button: 0 })
      .trigger('mousemove', { pageX: 600, pageY: 600 }) // call large number, beyoud max width/height
      .trigger('mouseup', { button: 0 })
      .then(() => {
        cy.get('img').then(($img) => {
          const height = $img.height()
          const width = $img.width()
          // this is their max width and height
          expect(width).to.eq(200)
          expect(height).to.eq(200)
        })
      })
  })
})
