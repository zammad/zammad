// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '@cy/utils'
import { FormValidationVisibility } from '@shared/components/Form/types'

describe('testing visuals for "FieldInput"', () => {
  const inputs = [
    { type: 'text', input: 'Some Text' },
    { type: 'email', input: 'some@mail.com' },
    { type: 'number', input: '100' },
    { type: 'tel', input: '123456789' },
    { type: 'time', input: '12:12' },
  ]

  inputs.forEach(({ type, input }) => {
    it(`renders usual ${type}`, () => {
      mountFormField(type, { label: type })
      checkFormMatchesSnapshot('basic', type)
      cy.get('input')
        .focus()
        .then(() => {
          checkFormMatchesSnapshot('basic - focused', type)
        })
      cy.get('input')
        .type(input)
        .then(() => {
          checkFormMatchesSnapshot('basic - filled', type)
        })
    })

    it(`renders required ${type}`, () => {
      mountFormField(type, { label: type, required: true })
      checkFormMatchesSnapshot('required', type)
      cy.get('input')
        .focus()
        .then(() => {
          checkFormMatchesSnapshot('required - focused', type)
        })
      cy.get('input')
        .type(input)
        .then(() => {
          checkFormMatchesSnapshot('required - filled', type)
        })
    })

    it(`renders invalid ${type}`, () => {
      mountFormField(type, {
        label: type,
        required: true,
        validationVisibility: FormValidationVisibility.Live,
      })
      checkFormMatchesSnapshot('required - invalid', type)
    })

    it(`renders linked ${type}`, () => {
      mountFormField(type, { label: type, link: '/' })
      checkFormMatchesSnapshot('linked', type)
      cy.get('input')
        .focus()
        .then(() => {
          checkFormMatchesSnapshot('linked - focused', type)
        })
      cy.get('input')
        .type(input)
        .then(() => {
          checkFormMatchesSnapshot('linked - filled', type)
        })
    })

    it(`renders disabled ${type}`, () => {
      mountFormField(type, { label: type, disabled: true })
      checkFormMatchesSnapshot('disabled', type)
    })
  })
})
