// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverSelect } from '../select.ts'

describe('FieldResolverSelect', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverSelect(EnumObjectManagerObjects.Ticket, {
      dataType: 'select',
      name: 'category',
      display: 'Category',
      dataOption: {
        translate: true,
        options: {
          i: 'a',
          ii: 'b',
          iii: 'c',
        },
        historical_options: {
          i: 'a',
          ii: 'b',
          iii: 'c',
          iv: 'd',
        },
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Category',
      name: 'category',
      required: false,
      props: {
        noOptionsLabelTranslation: false,
        clearable: false,
        options: [
          {
            label: 'a',
            value: 'i',
          },
          {
            label: 'b',
            value: 'ii',
          },
          {
            label: 'c',
            value: 'iii',
          },
        ],
        historicalOptions: {
          i: 'a',
          ii: 'b',
          iii: 'c',
          iv: 'd',
        },
        // Object-keyed static options have no stable iteration order, so the
        // resolver requests label sorting (consistent with relation-typed
        // selects, where the server-resolved order isn't a display contract).
        sorting: 'label',
      },
      type: 'select',
      internal: true,
    })
  })

  it('does not request label sorting for array-shaped static options (order is already given)', () => {
    const fieldResolver = new FieldResolverSelect(EnumObjectManagerObjects.Ticket, {
      dataType: 'select',
      name: 'category',
      display: 'Category',
      dataOption: {
        translate: true,
        options: [
          { name: 'A', value: 'a' },
          { name: 'B', value: 'b' },
        ],
        historical_options: {},
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes().props).not.toHaveProperty('sorting')
    expect(fieldResolver.getFilterOperatorProps()?.is).not.toHaveProperty('sorting')
  })

  it('should return the correct field attributes for relations', () => {
    const fieldResolver = new FieldResolverSelect(EnumObjectManagerObjects.Ticket, {
      dataType: 'select',
      name: 'category',
      display: 'Category',
      dataOption: {
        historical_options: {},
        translate: true,
        options: {},
        relation: 'Group',
        belongs_to: 'group',
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Category',
      name: 'category',
      required: false,
      props: {
        historicalOptions: {},
        noOptionsLabelTranslation: false,
        clearable: false,
        options: [],
        belongsToObjectField: 'group',
        sorting: 'label',
      },
      relation: {
        type: 'Group',
      },
      type: 'select',
      internal: true,
    })
  })

  it('omits the options key for relation-typed attributes (options come from the form updater)', () => {
    const fieldResolver = new FieldResolverSelect(EnumObjectManagerObjects.Ticket, {
      dataType: 'select',
      name: 'group_id',
      display: 'Group',
      dataOption: {
        translate: true,
        relation: 'Group',
        belongs_to: 'group',
      },
      isInternal: true,
    })

    expect(fieldResolver.getFilterOperatorProps()).toEqual({
      is: {
        noOptionsLabelTranslation: false,
        historicalOptions: undefined,
        sorting: 'label',
      },
    })
  })

  it('provides select filter fields for the is operator', () => {
    const fieldResolver = new FieldResolverSelect(EnumObjectManagerObjects.Ticket, {
      dataType: 'select',
      name: 'category',
      display: 'Category',
      dataOption: {
        translate: true,
        options: {
          i: 'a',
          ii: 'b',
        },
        historical_options: {
          i: 'a',
          ii: 'b',
        },
      },
      isInternal: true,
    })

    expect(fieldResolver.getFilterOperatorProps()).toEqual({
      is: {
        noOptionsLabelTranslation: false,
        options: [
          { label: 'a', value: 'i' },
          { label: 'b', value: 'ii' },
        ],
        historicalOptions: {
          i: 'a',
          ii: 'b',
        },
        sorting: 'label',
      },
    })
  })

  describe('getFilterAutocompleteType', () => {
    const buildResolver = (
      name: string,
      dataOption: Record<string, string | Record<string, string>>,
    ) =>
      new FieldResolverSelect(EnumObjectManagerObjects.Ticket, {
        dataType: 'select',
        name,
        display: 'Attr',
        dataOption,
        isInternal: true,
      })

    it('returns the customer picker for plain User relations', () => {
      expect(buildResolver('customer_id', { relation: 'User' }).getFilterAutocompleteType()).toBe(
        'customer',
      )
    })

    it('returns the organization picker for Organization relations', () => {
      expect(
        buildResolver('organization_id', { relation: 'Organization' }).getFilterAutocompleteType(),
      ).toBe('organization')
    })

    it('returns the agent picker for owner_id (name override beats the User → customer mapping)', () => {
      expect(buildResolver('owner_id', { relation: 'User' }).getFilterAutocompleteType()).toBe(
        'agent',
      )
    })

    it('returns undefined for non-autocomplete relations', () => {
      expect(buildResolver('group_id', { relation: 'Group' }).getFilterAutocompleteType()).toBe(
        undefined,
      )
    })

    it('returns undefined for attributes without a relation', () => {
      expect(
        buildResolver('category', { options: { a: 'a' } }).getFilterAutocompleteType(),
      ).toBeUndefined()
    })
  })

  describe('getFilterRelation', () => {
    const buildResolver = (
      name: string,
      dataOption: Record<string, string | Record<string, string>>,
    ) =>
      new FieldResolverSelect(EnumObjectManagerObjects.Ticket, {
        dataType: 'select',
        name,
        display: 'Attr',
        dataOption,
        isInternal: true,
      })

    it('returns the relation for form-updater-resolvable attributes', () => {
      expect(buildResolver('group_id', { relation: 'Group' }).getFilterRelation()).toBe('Group')
    })

    it('also returns the relation when an autocomplete picker is active', () => {
      // `relation` and `autocompleteFilterType` are not mutually exclusive:
      // the relation signals "value is a foreign-key ID" (drives downstream
      // coercion), the autocomplete type signals "UI fetches per keystroke".
      // Both are emitted; consumers gate on autocompleteFilterType to choose
      // their path.
      expect(buildResolver('customer_id', { relation: 'User' }).getFilterRelation()).toBe('User')
      expect(buildResolver('owner_id', { relation: 'User' }).getFilterRelation()).toBe('User')
      expect(
        buildResolver('organization_id', { relation: 'Organization' }).getFilterRelation(),
      ).toBe('Organization')
    })

    it('returns undefined for attributes without a relation', () => {
      expect(buildResolver('category', { options: { a: 'a' } }).getFilterRelation()).toBeUndefined()
    })
  })
})
