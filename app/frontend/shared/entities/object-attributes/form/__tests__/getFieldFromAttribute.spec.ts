// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import getFieldFromAttribute, {
  transformResolvedFieldForScreen,
} from '../getFieldFromAttribute.ts'

const objectAttribute = {
  dataType: 'input',
  name: 'title',
  display: 'Title',
  dataOption: {
    type: 'text',
    maxlength: 100,
  },
  isInternal: true,
}

const expectedFieldSchemaBase = {
  label: 'Title',
  name: 'title',
  required: false,
  props: {
    maxlength: 100,
  },
  type: 'text',
  internal: true,
}

describe('object attribute correctly resolved as field schema', () => {
  it('should return the correct field schema', () => {
    const fieldSchema = getFieldFromAttribute(
      EnumObjectManagerObjects.Ticket,
      objectAttribute,
    )

    expect(fieldSchema).toEqual(expectedFieldSchemaBase)
  })
})

describe('transform resolved field for given screen', () => {
  it('should return the correct required value', () => {
    const fieldSchema = getFieldFromAttribute(
      EnumObjectManagerObjects.Ticket,
      objectAttribute,
    )

    transformResolvedFieldForScreen({ required: true }, fieldSchema)

    expect(fieldSchema).toEqual({
      ...expectedFieldSchemaBase,
      required: true,
    })
  })

  it('should return the correct required value for null screen value', () => {
    const fieldSchema = getFieldFromAttribute(
      EnumObjectManagerObjects.Ticket,
      objectAttribute,
    )

    transformResolvedFieldForScreen({ null: false }, fieldSchema)

    expect(fieldSchema).toEqual({
      ...expectedFieldSchemaBase,
      required: true,
    })
  })

  it('should return the correct required value for null screen value', () => {
    const fieldSchema = getFieldFromAttribute(
      EnumObjectManagerObjects.Ticket,
      objectAttribute,
    )

    transformResolvedFieldForScreen({ null: true }, fieldSchema)

    expect(fieldSchema).toEqual({
      ...expectedFieldSchemaBase,
      required: false,
    })
  })
})
