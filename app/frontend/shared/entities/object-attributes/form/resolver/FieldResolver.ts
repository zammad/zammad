// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldValue, FormSchemaField } from '#shared/components/Form/types.ts'
import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import type { ObjectAttribute, OperatorFilterProps } from '../../types/store.ts'
import type { JsonValue } from 'type-fest'

// Relations whose advanced-filter input is an autocomplete (per-keystroke
// query) rather than a server-resolved option list. Values are the FormKit
// field types to render. Consulted by resolvers to split a relation into
// the right pair of signals on FilterAttribute.
export const AUTOCOMPLETE_FILTER_FIELD_BY_RELATION: Record<string, string> = {
  User: 'customer',
  Organization: 'organization',
}

export abstract class FieldResolver {
  protected name: string

  protected object: EnumObjectManagerObjects

  protected label: string

  protected internal: boolean

  protected attributeType: string

  protected attributeConfig: Record<string, JsonValue | undefined>

  abstract fieldType: string | (() => string)

  constructor(object: EnumObjectManagerObjects, objectAttribute: ObjectAttribute) {
    this.object = object
    this.name = objectAttribute.name
    this.label = objectAttribute.display
    this.internal = objectAttribute.isInternal
    this.attributeType = objectAttribute.dataType
    this.attributeConfig = objectAttribute.dataOption || {}
  }

  private getFieldType(): string {
    if (typeof this.fieldType === 'function') return this.fieldType()

    return this.fieldType
  }

  /**
   * Operators supported by this attribute for advanced search.
   * Returning undefined means the attribute is not filterable.
   * Strings keep this open for addons that introduce custom operators.
   */
  public getFieldFilterOperators(): string[] | undefined {
    return
  }

  public getFilterOperatorProps(): OperatorFilterProps | undefined {
    return
  }

  /**
   * Advanced-filter relation type name (e.g. 'Group', 'TicketState') for
   * attributes whose options are resolved by the form-updater backend.
   * Returns undefined for autocomplete-style relations — those are surfaced
   * via getFilterAutocompleteType() instead.
   */
  public getFilterRelation(): string | undefined {
    return
  }

  /**
   * Advanced-filter FormKit field type (e.g. 'customer', 'organization') for
   * attributes whose options come from a per-keystroke autocomplete query
   * rather than the form-updater backend.
   */
  public getFilterAutocompleteType(): string | undefined {
    return
  }

  public fieldAttributes(): FormSchemaField {
    const resolvedAttributes: FormSchemaField = {
      type: this.getFieldType(),
      label: this.label,
      name: this.name,
      required: 'null' in this.attributeConfig && !this.attributeConfig.null, // will normally be overriden with the screen config
      help: this.attributeConfig.note as string | undefined,
      internal: this.internal,
      ...this.fieldTypeAttributes(),
    }

    if (this.attributeConfig.default) {
      resolvedAttributes.value = this.attributeConfig.default as FormFieldValue
    }

    // TODO: Support half-sized/single column fields based on the information hard-coded in the object attribute
    //   backend for now. Later we can make this a concern of the frontend only, and ignore the hard-coded values.
    // Support half-sized/single column fields based on the information hard-coded in the object attribute backend.
    // Both 'formGroup--halfSize' (custom attributes) and 'column' (core ticket fields) indicate single-column layout.
    const itemClass =
      typeof this.attributeConfig.item_class === 'string'
        ? this.attributeConfig.item_class
        : undefined
    if (
      itemClass &&
      (itemClass.indexOf('formGroup--halfSize') !== -1 || itemClass.indexOf('column') !== -1)
    ) {
      resolvedAttributes.outerClass = 'form-group-single-column'
    }

    return resolvedAttributes
  }

  abstract fieldTypeAttributes(): Partial<FormSchemaField>

  transformFieldValue?(value: FormFieldValue): FormFieldValue
}
