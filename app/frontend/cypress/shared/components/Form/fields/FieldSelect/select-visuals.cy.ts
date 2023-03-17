// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '@cy/utils'
import { FormValidationVisibility } from '@shared/components/Form/types'

const options = [
  {
    value: 0,
    label: 'Item A',
  },
  {
    value: 1,
    label: 'Item B',
  },
  {
    value: 2,
    label: 'Item C',
  },
  {
    value: 3,
    label: 'Item D',
  },
  {
    value: 4,
    label: 'Item E',
  },
  {
    value: 5,
    label:
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vestibulum sem quis purus elementum pulvinar. Quisque placerat nibh et dignissim tincidunt. Morbi semper tortor at dolor mollis laoreet. Aenean fringilla fermentum leo non finibus. Nulla porttitor lacus diam, at vestibulum risus viverra a',
  },
  {
    value: 6,
    label: 'Item F',
  },
  {
    value: 7,
    label: 'Item G',
  },
  {
    value: 8,
    label: 'Item H',
  },
]

const value = 0
const values = [0, 1]

describe('testing visuals for "FieldSelect"', () => {
  it('renders basic select', () => {
    mountFormField('select', { label: 'select' })
    checkFormMatchesSnapshot()
  })
  it('renders basic disabled select', () => {
    mountFormField('select', { label: 'select', disabled: true })
    checkFormMatchesSnapshot()
  })
  it('renders basic required select', () => {
    mountFormField('select', { label: 'select', required: true })
    checkFormMatchesSnapshot()
  })
  it('renders basic invalid select', () => {
    mountFormField('select', {
      label: 'select',
      required: true,
      validationVisibility: FormValidationVisibility.Live,
    })
    checkFormMatchesSnapshot()
  })
  it(`renders focused select`, () => {
    mountFormField('select', { label: 'select' })
    cy.get('output')
      .focus()
      .then(() => {
        checkFormMatchesSnapshot()
      })
  })
  it(`renders focused linked select`, () => {
    mountFormField('select', { label: 'select', link: '/' })
    cy.get('output')
      .focus()
      .then(() => {
        checkFormMatchesSnapshot()
      })
  })

  it('renders linked select', () => {
    mountFormField('select', { label: 'select', link: '/' })
    checkFormMatchesSnapshot()
  })

  it('renders selected select', () => {
    mountFormField('select', { label: 'select', options, value })
    checkFormMatchesSnapshot()
  })
  it('renders selected disabled select', () => {
    mountFormField('select', {
      label: 'select',
      options,
      value,
      disabled: true,
    })
    checkFormMatchesSnapshot()
  })
  it('renders selected required select', () => {
    mountFormField('select', {
      label: 'select',
      options,
      value,
      required: true,
    })
    checkFormMatchesSnapshot()
  })
  it('renders selected select linked', () => {
    mountFormField('select', { label: 'select', options, value, link: '/' })
    checkFormMatchesSnapshot()
  })

  it('renders multiple selected select', () => {
    mountFormField('select', {
      label: 'select',
      options,
      value: values,
      multiple: true,
    })
    checkFormMatchesSnapshot()
  })
  it('renders multiple selected disabled select', () => {
    mountFormField('select', {
      label: 'select',
      options,
      value: values,
      multiple: true,
      disabled: true,
    })
    checkFormMatchesSnapshot()
  })
  it('renders multiple selected required select', () => {
    mountFormField('select', {
      label: 'select',
      options,
      value: values,
      multiple: true,
      required: true,
    })
    checkFormMatchesSnapshot()
  })

  it('renders long multiple selected', () => {
    mountFormField('select', {
      label: 'select',
      options,
      value: [0, 1, 2, 3, 4, 6, 7, 8],
      multiple: true,
    })
    checkFormMatchesSnapshot()
  })

  it('renders long selected', () => {
    mountFormField('select', {
      label: 'select',
      options,
      value: 5,
    })
    checkFormMatchesSnapshot()
  })
})
