// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import { camelize } from '@shared/utils/formatter'
import FieldResolver from '../FieldResolver'

export class FieldResolverAutocompletion extends FieldResolver {
  fieldType = () => {
    switch (this.attributeConfig.relation) {
      case 'Organization':
        return 'organization'
      case 'User':
        return 'customer'
      case 'Group':
      case 'TicketState':
      case 'TicketPriority':
        throw new Error(
          `Relation ${this.attributeConfig.relation} is not implemented yet`,
        )
      // TODO which relation is recipient?
      default:
        throw new Error(`Unknown relation ${this.attributeConfig.relation}`)
    }
  }

  public fieldTypeAttributes() {
    return {
      props: {
        noOptionsLabelTranslation: !this.attributeConfig.translate,
        belongsToObjectField: camelize(
          (this.attributeConfig.belongs_to as string) || '',
        ),
        multiple: this.attributeConfig.multiple,
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'autocompletion_ajax',
  resolver: FieldResolverAutocompletion,
}
