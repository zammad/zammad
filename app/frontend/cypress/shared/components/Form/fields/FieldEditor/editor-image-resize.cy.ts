// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  it('preserves resized width/height when an article/draft body is reloaded from saved HTML', () => {
    cy.intercept('GET', '/api/v1/attachments/2062', { fixture: 'example.png' })

    // This is the shape actually persisted for an article/shared-draft body: HtmlSanitizer.strict
    // (via HtmlSanitizer::Scrubber::Wipe#move_attrs_to_css) moves width/height off the element and
    // into an inline style with a 'px' suffix, so this - not the plain-attribute form below - is
    // what a user reproducing #809 hits on reload (regression test for the style fallback
    // stripping the 'px' unit rather than leaving it in place, which browsers ignore).
    mountEditor({
      value: '<p><img src="/api/v1/attachments/2062" style="width:83px;height:83px"></p>',
    })

    cy.get('img').then(($img) => {
      expect($img.width()).to.eq(83)
      expect($img.height()).to.eq(83)
    })
  })

  it('preserves resized width/height when reloaded via plain width/height attributes', () => {
    cy.intercept('GET', '/api/v1/attachments/2062', { fixture: 'example.png' })

    // This is the shape produced by the editor's own renderHTML for a resized image (plain
    // width/height attributes, no inline style). It's not how a saved article/draft body comes
    // back (that goes through HtmlSanitizer.strict and ends up as an inline style instead - see
    // the case above), but it is what round-trips through an editor -> clipboard -> editor copy,
    // e.g. pasting a resized image from one compose window into another (regression test for
    // parseHTML falling back to schema defaults).
    mountEditor({
      value: '<p><img src="/api/v1/attachments/2062" width="83" height="83"></p>',
    })

    cy.get('img').should('have.attr', 'width', '83').and('have.attr', 'height', '83')
  })
})
