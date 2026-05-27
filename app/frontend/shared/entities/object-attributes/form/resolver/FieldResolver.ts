// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldValue, FormSchemaField } from '#shared/components/Form/types.ts'
import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { capitalize } from '#shared/utils/formatter.ts'

import type { ObjectAttribute, OperatorFilterProps } from '../../types/store.ts'
import type { JsonValue } from 'type-fest'

// Maps a `FormUpdater::Relation::*`-style key to the FormKit field type that
// renders its autocomplete in the advanced filter. The key namespace is the
// same on both sides of the FieldResolver lookup — e.g. `Owner` is a valid
// key just like `User` is — which keeps the table single-purpose.
const AUTOCOMPLETE_FILTER_FIELDS: Record<string, string> = {
  User: 'customer',
  Organization: 'organization',
  Owner: 'agent',
}

export abstract class FieldResolver {
  protected name: string

  protected object: EnumObjectManagerObjects

  protected label: string

  protected internal: boolean

  protected attributeType: string

  protected attributeConfig: Record<string, JsonValue | undefined>

  abstract fieldType: string | (() => string)

  /**
   * Cached at construction so all instance methods (and subclass logic that
   * needs to react to the autocomplete-vs-relation split) can read the same
   * derived value without re-running the dispatch.
   */
  protected filterAutocompleteType: string | undefined

  constructor(object: EnumObjectManagerObjects, objectAttribute: ObjectAttribute) {
    this.object = object
    this.name = objectAttribute.name
    this.label = objectAttribute.display
    this.internal = objectAttribute.isInternal
    this.attributeType = objectAttribute.dataType
    this.attributeConfig = objectAttribute.dataOption || {}

    this.filterAutocompleteType = this.computeFilterAutocompleteType()
  }

  // Subclasses that need additional one-shot setup derived from
  // `this.attributeConfig` etc. extend the constructor in the usual way:
  // `constructor(...) { super(...); /* their own setup */ }`. The base
  // class assigns its own properties first so subclass code can read them.

  private computeFilterAutocompleteType(): string | undefined {
    const nameKey = capitalize(this.name.replace(/_id$/, ''))
    if (AUTOCOMPLETE_FILTER_FIELDS[nameKey]) return AUTOCOMPLETE_FILTER_FIELDS[nameKey]

    const relation = this.attributeConfig.relation as string | undefined
    return relation ? AUTOCOMPLETE_FILTER_FIELDS[relation] : undefined
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
   * rather than the form-updater backend. Computed once in the constructor
   * (see `computeFilterAutocompleteType`) so callers and subclasses can
   * read the cached value cheaply via `this.filterAutocompleteType`.
   */
  public getFilterAutocompleteType(): string | undefined {
    return this.filterAutocompleteType
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
