// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '@cy/utils'
import { FormValidationVisibility } from '@shared/components/Form/types'

const longText =
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vestibulum sem quis purus elementum pulvinar. Quisque placerat nibh et dignissim tincidunt. Morbi semper tortor at dolor mollis laoreet. Aenean fringilla fermentum leo non finibus. Nulla porttitor lacus diam, at vestibulum risus viverra a'

describe('testing visuals for "FieldTags"', () => {
  it('renders basic tags', () => {
    mountFormField('tags', { label: 'tags' })
    checkFormMatchesSnapshot('basic')
  })

  it('renders linked tags', () => {
    mountFormField('tags', { label: 'tags', link: '/' })
    checkFormMatchesSnapshot('linked')
  })

  it('renders required tags', () => {
    mountFormField('tags', { label: 'tags', required: true })
    checkFormMatchesSnapshot('required')
  })

  it('renders invalid tags', () => {
    mountFormField('tags', {
      label: 'select',
      required: true,
      validationVisibility: FormValidationVisibility.Live,
    })
    checkFormMatchesSnapshot('invalid')
  })

  it(`renders focused tags`, () => {
    mountFormField('tags', { label: 'select' })
    cy.get('output')
      .focus()
      .then(() => {
        checkFormMatchesSnapshot('focused')
      })
  })

  it(`renders focused linked tags`, () => {
    mountFormField('tags', { label: 'select', link: '/' })
    cy.get('output')
      .focus()
      .then(() => {
        checkFormMatchesSnapshot('focused - linked')
      })
  })

  it('renders selected tags', () => {
    mountFormField('tags', { label: 'tags', value: ['some', 'thing'] })
    checkFormMatchesSnapshot('selected')
  })

  it('renders selected with link tags', () => {
    mountFormField('tags', {
      label: 'tags',
      value: ['some', 'thing'],
      link: '/',
    })
    checkFormMatchesSnapshot('selected - linked')
  })

  it('renders a lot of selected tags', () => {
    mountFormField('tags', {
      label: 'tags',
      value: Array.from(new Set(longText.split(' '))),
    })
    checkFormMatchesSnapshot('selected - a lot')
  })
})
