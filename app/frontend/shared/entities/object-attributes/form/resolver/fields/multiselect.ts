// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import { FieldResolverSelect } from './select.ts'

export class FieldResolverMultiselect extends FieldResolverSelect {}

export default <FieldResolverModule>{
  type: 'multiselect',
  resolver: FieldResolverMultiselect,
}
