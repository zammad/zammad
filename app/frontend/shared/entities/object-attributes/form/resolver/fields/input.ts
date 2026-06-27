// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldAdditionalProps } from '#shared/components/Form/types.ts'
import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import { FieldResolver } from '../FieldResolver.ts'

export class FieldResolverInput extends FieldResolver {
  fieldType = () => {
    switch (this.attributeConfig.type) {
      case 'password':
        return 'password'
      case 'tel':
        return 'tel'
      case 'email':
        return 'email'
      case 'url':
        return 'url'
      default:
        return 'text'
    }
  }

  get filterable() {
    return this.attributeConfig.type !== 'password'
  }

  public override getFieldFilterOperators() {
    if (!this.filterable) return

    return ['matches']
  }

  public fieldTypeAttributes() {
    const props: FormFieldAdditionalProps = {
      maxlength: this.attributeConfig.maxlength,
    }

    // In case of password attributes, we want to prevent the browser autofill mechanism from filling empty fields.
    //   We do that by setting the autocomplete attribute on the field.
    //   This attribute is a hint to browsers; some may not comply with it.
    //   https://developer.mozilla.org/en-US/docs/Web/Security/Practical_implementation_guides/Turning_off_form_autocompletion#managing_autofill_for_login_fields
    if (this.attributeConfig.type === 'password') {
      props.autocomplete = 'new-password'
    }

    const validation = this.validation()

    if (validation) {
      props.validation = validation
    }

    return {
      props,
    }
  }

  private validation() {
    switch (this.attributeConfig.type) {
      case 'email':
        return 'email'
      case 'url':
        return 'url'
      default:
        return null
    }
  }
}

export default <FieldResolverModule>{
  type: 'input',
  resolver: FieldResolverInput,
}
