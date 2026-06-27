// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverTag } from '../tag.ts'

describe('FieldResolverTag', () => {
  const buildResolver = () =>
    new FieldResolverTag(EnumObjectManagerObjects.Ticket, {
      dataType: 'tag',
      name: 'tags',
      display: 'Tags',
      dataOption: {
        type: 'text',
        null: true,
        translate: false,
      },
      isInternal: true,
    })

  it('should return the correct field attributes', () => {
    mockApplicationConfig({
      tag_new: true,
    })

    const fieldResolver = new FieldResolverTag(EnumObjectManagerObjects.Ticket, {
      dataType: 'tag',
      name: 'tag',
      display: 'Tag',
      dataOption: {
        type: 'text',
        null: true,
        translate: false,
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Tag',
      name: 'tag',
      required: false,
      props: {
        canCreate: true,
      },
      type: 'tags',
      internal: true,
    })
  })

  it('exposes the `contains one` operator for advanced search filters', () => {
    expect(buildResolver().getFieldFilterOperators()).toEqual(['contains one'])
  })

  it('routes through the tag autocomplete picker', () => {
    expect(buildResolver().getFilterAutocompleteType()).toBe('tags')
  })

  it('disables canCreate for the filter picker', () => {
    // Only existing tags can match a filter, so canCreate is off; and the
    // popular-tags default list is suppressed (empty defaultFilter) because
    // search filters are typed against, not browsed.
    expect(buildResolver().getFilterOperatorProps()).toEqual({
      'contains one': { canCreate: false },
    })
  })

  it('keeps the filter picker locked to canCreate=false even when tag_new is enabled', () => {
    // The standard form's `fieldTypeAttributes()` honours `tag_new` to let
    // users invent tags, but a filter that matches against existing data has
    // no use for that mode — confirm the filter-side props don't pick the
    // global config up.
    mockApplicationConfig({
      tag_new: true,
    })

    expect(buildResolver().getFilterOperatorProps()).toEqual({
      'contains one': { canCreate: false },
    })
  })
})
