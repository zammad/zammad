// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import { FieldResolver } from '../FieldResolver.ts'

export class FieldResolverTag extends FieldResolver {
  fieldType = 'tags'

  public fieldTypeAttributes() {
    const application = useApplicationStore()

    return {
      props: {
        canCreate: Boolean(application.config.tag_new),
      },
    }
  }

  public override getFieldFilterOperators() {
    // Tags use the historic `contains one` operator (also used by overview /
    // trigger conditions and routed through the existing ES + SQL selector
    // paths). Other relation / autocomplete attributes keep `is`.
    return ['contains one']
  }

  public override getFilterOperatorProps() {
    // The standard form field allows creating new tags when configured, but a
    // search filter should only match against tags that exist — inventing a
    // tag name here would yield no results by definition.
    return { 'contains one': { canCreate: false } }
  }
}

export default <FieldResolverModule>{
  type: 'tag',
  resolver: FieldResolverTag,
}
