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
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vestibulum sem quis purus elementum pulvinar.',
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

describe('testing visuals for "FieldAutocomplete"', () => {
  const inputs = [
    { type: 'customer' },
    { type: 'organization' },
    { type: 'autocomplete' },
    { type: 'recipient' },
  ]

  inputs.forEach(({ type }) => {
    it(`renders basic ${type}`, () => {
      mountFormField(type, { label: type, options })
      checkFormMatchesSnapshot({ type })
    })
    it(`renders basic disabled ${type}`, () => {
      mountFormField(type, { label: type, options, disabled: true })
      checkFormMatchesSnapshot({ type })
    })
    it(`renders basic required ${type}`, () => {
      mountFormField(type, { label: type, options, required: true })
      checkFormMatchesSnapshot({ type })
    })
    it(`renders basic invalid ${type}`, () => {
      mountFormField(type, {
        label: type,
        options,
        required: true,
        validationVisibility: FormValidationVisibility.Live,
      })
      checkFormMatchesSnapshot({ type })
    })

    it(`renders selected ${type}`, () => {
      mountFormField(type, { label: type, options, value: 0 })
      checkFormMatchesSnapshot({ type })
    })
    it(`renders selected disabled ${type}`, () => {
      mountFormField(type, { label: type, options, value: 0, disabled: true })
      checkFormMatchesSnapshot({ type })
    })
    it(`renders selected required ${type}`, () => {
      mountFormField(type, { label: type, options, value: 0, required: true })
      checkFormMatchesSnapshot({ type })
    })

    it(`renders focused ${type}`, () => {
      mountFormField(type, { label: type, options })
      cy.get('output')
        .focus()
        .then(() => {
          checkFormMatchesSnapshot({ type })
        })
    })

    it(`renders focused linked ${type}`, () => {
      mountFormField(type, { label: type, options, link: '/' })
      cy.get('output')
        .focus()
        .then(() => {
          checkFormMatchesSnapshot({ type })
        })
    })

    it(`renders multiple ${type}`, () => {
      mountFormField(type, {
        label: type,
        options,
        multiple: true,
        value: [0, 1],
      })
      checkFormMatchesSnapshot({ type })
    })
    it(`renders multiple disabled ${type}`, () => {
      mountFormField(type, {
        label: type,
        options,
        multiple: true,
        value: [0, 1],
        disabled: true,
      })
      checkFormMatchesSnapshot({ type })
    })
    it(`renders multiple required ${type}`, () => {
      mountFormField(type, {
        label: type,
        options,
        multiple: true,
        value: [0, 1],
        required: true,
      })
      checkFormMatchesSnapshot({ type })
    })

    it(`renders long ${type}`, () => {
      mountFormField(type, { label: type, value: 5, options })
      checkFormMatchesSnapshot({
        type,
        assertion: ($el) => {
          expect($el.height()).to.be.above(60)
          return $el
        },
      })
    })
  })
})
