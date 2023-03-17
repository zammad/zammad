// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '@cy/utils'
import { FormValidationVisibility } from '@shared/components/Form/types'

const options = [
  {
    value: 0,
    label: 'Item A',
    children: [
      {
        value: 1,
        label: 'Item 1',
        children: [
          {
            value: 2,
            label: 'Item I',
          },
          {
            value: 3,
            label: 'Item II',
          },
          {
            value: 4,
            label: 'Item III',
          },
        ],
      },
      {
        value: 5,
        label:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vestibulum sem quis purus elementum pulvinar.',
        children: [
          {
            value: 6,
            label: 'Item IV',
          },
        ],
      },
      {
        value: 7,
        label: 'Item 3',
      },
    ],
  },
  {
    value: 8,
    label: 'Item B',
  },
  {
    value: 9,
    label: 'Ítem C',
  },
]

const value = 0

describe('testing visuals for "FieldTreeSelect"', () => {
  it('renders basic disabled select', () => {
    mountFormField('treeselect', {
      label: 'treeselect',
      disabled: true,
    })
    checkFormMatchesSnapshot()
  })
  it('renders basic required select', () => {
    mountFormField('treeselect', {
      label: 'treeselect',
      required: true,
    })
    checkFormMatchesSnapshot()
  })
  it('renders basic invalid treeselect', () => {
    mountFormField('treeselect', {
      label: 'treeselect',
      required: true,
      validationVisibility: FormValidationVisibility.Live,
    })
    checkFormMatchesSnapshot()
  })

  it(`renders focused treeselect`, () => {
    mountFormField('treeselect', { label: 'treeselect' })
    cy.get('output')
      .focus()
      .then(() => {
        checkFormMatchesSnapshot()
      })
  })
  it(`renders focused linked treeselect`, () => {
    mountFormField('treeselect', { label: 'treeselect', link: '/' })
    cy.get('output')
      .focus()
      .then(() => {
        checkFormMatchesSnapshot()
      })
  })

  it('renders linked select', () => {
    mountFormField('treeselect', { label: 'treeselect', link: '/' })
    checkFormMatchesSnapshot()
  })

  it('renders selected select', () => {
    mountFormField('treeselect', { label: 'treeselect', options, value })
    checkFormMatchesSnapshot()
  })
  it('renders selected disabled select', () => {
    mountFormField('treeselect', {
      label: 'treeselect',
      options,
      value,
      disabled: true,
    })
    checkFormMatchesSnapshot()
  })
  it('renders selected required select', () => {
    mountFormField('treeselect', {
      label: 'treeselect',
      options,
      value,
      required: true,
    })
    checkFormMatchesSnapshot()
  })
  it('renders selected select linked', () => {
    mountFormField('treeselect', {
      label: 'treeselect',
      options,
      value,
      link: '/',
    })
    checkFormMatchesSnapshot()
  })

  it('renders multiple selected select', () => {
    mountFormField('treeselect', {
      label: 'treeselect',
      options,
      value: [0, 1],
      multiple: true,
    })
    checkFormMatchesSnapshot()
  })
  it('renders multiple selected disabled select', () => {
    mountFormField('treeselect', {
      label: 'treeselect',
      options,
      value: [0, 1],
      multiple: true,
      disabled: true,
    })
    checkFormMatchesSnapshot()
  })
  it('renders multiple selected required select', () => {
    mountFormField('treeselect', {
      label: 'treeselect',
      options,
      value: [0, 1],
      multiple: true,
      required: true,
    })
    checkFormMatchesSnapshot()
  })

  it('renders long multiple selected', () => {
    mountFormField('treeselect', {
      label: 'treeselect',
      options,
      value: [0, 1, 2, 3, 4, 6, 7, 8],
      multiple: true,
    })
    checkFormMatchesSnapshot()
  })

  it('renders long selected', () => {
    mountFormField('treeselect', {
      label: 'treeselect',
      options,
      value: 5,
    })
    checkFormMatchesSnapshot()
  })
})
