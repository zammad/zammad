// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import { FieldResolverTreeselect } from './treeselect.ts'

export class FieldResolverMultiTreeselect extends FieldResolverTreeselect {}

export default <FieldResolverModule>{
  type: 'multi_tree_select',
  resolver: FieldResolverMultiTreeselect,
}
