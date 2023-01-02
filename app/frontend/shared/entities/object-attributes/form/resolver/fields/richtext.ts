// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverRichtext extends FieldResolver {
  fieldType = 'editor'

  // TODO:
  // def field_for_oa_type_richtext(context:, attribute:)
  //   FormSchema::Field::Editor.new(
  //     **base_attributes(context: context, attribute: attribute),
  //     // TODO: the OA has a maxlength attribute, but Field::Editor does not support that yet.
  //     // maxlength: attribute[:data_option]['maxlength']
  //   )
  // end
  // eslint-disable-next-line class-methods-use-this
  public fieldTypeAttributes() {
    return {
      props: {},
    }
  }
}

export default <FieldResolverModule>{
  type: 'richtext',
  resolver: FieldResolverRichtext,
}
