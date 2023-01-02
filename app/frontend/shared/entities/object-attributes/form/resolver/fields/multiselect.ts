// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import { FieldResolverSelect } from './select'

export class FieldResolverMultiselect extends FieldResolverSelect {}

export default <FieldResolverModule>{
  type: 'multiselect',
  resolver: FieldResolverMultiselect,
}
