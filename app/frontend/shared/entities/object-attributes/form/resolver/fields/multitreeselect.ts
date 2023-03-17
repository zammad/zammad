// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import { FieldResolverTreeselect } from './treeselect'

export class FieldResolverMultiTreeselect extends FieldResolverTreeselect {}

export default <FieldResolverModule>{
  type: 'multi_tree_select',
  resolver: FieldResolverMultiTreeselect,
}
