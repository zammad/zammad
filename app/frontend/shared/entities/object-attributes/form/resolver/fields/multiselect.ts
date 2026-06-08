// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import { FieldResolverSelect } from './select.ts'

export class FieldResolverMultiselect extends FieldResolverSelect {
  // Multi-value selects ship as `contains one` in the advanced filter —
  // matches the existing overview / trigger condition vocabulary and the
  // backend selector wiring for multi-value attributes.
  protected override filterOperatorName = 'contains one'
}

export default <FieldResolverModule>{
  type: 'multiselect',
  resolver: FieldResolverMultiselect,
}
