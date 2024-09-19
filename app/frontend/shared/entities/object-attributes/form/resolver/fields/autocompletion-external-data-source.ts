// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNodeByName } from '#shared/components/Form/utils.ts'
import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { ensureGraphqlId } from '#shared/graphql/utils.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import FieldResolver from '../FieldResolver.ts'

import type { JsonValue } from 'type-fest'

export class FieldResolverAutocompletionExternalDataSource extends FieldResolver {
  fieldType = 'externalDataSource'

  public fieldTypeAttributes() {
    return {
      props: {
        clearable: !!this.attributeConfig.nulloption,
        noOptionsLabelTranslation: !this.attributeConfig.translate,
        object: this.object,
        searchTemplateRenderContext: (
          formId: string,
          entityObject: ObjectLike,
        ) => {
          const templateRenderContext: Record<string, JsonValue> = {}

          switch (this.object) {
            case EnumObjectManagerObjects.Ticket:
              if (entityObject) {
                templateRenderContext.customerId = entityObject.customer?.id
              }

              if (!templateRenderContext.customerId) {
                const node = getNodeByName(formId, 'customer_id')
                const value = node?.value as string

                if (value) {
                  templateRenderContext.customerId = ensureGraphqlId(
                    'User',
                    value,
                  )
                }
              }

              return templateRenderContext
            case EnumObjectManagerObjects.User:
            case EnumObjectManagerObjects.Organization:
            case EnumObjectManagerObjects.Group:
            default:
              return templateRenderContext
          }
        },
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'autocompletion_ajax_external_data_source',
  resolver: FieldResolverAutocompletionExternalDataSource,
}
