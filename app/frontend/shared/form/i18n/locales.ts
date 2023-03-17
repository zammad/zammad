// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitValidationMessages } from '@formkit/validation'
import type { FormKitLocale } from '@formkit/i18n'
import { i18n } from '@shared/i18n'
import { commaSeparatedList, order } from '@shared/utils/formatter'

interface FormKitLocaleExtended extends FormKitLocale {
  validation: FormKitValidationMessages
}

// TODO: Use translateLabel for all validation messages if we stay with the labels inside of the messages. It's a open
// question if we want use them inside of the messages.

const loadLocales = (): FormKitLocaleExtended => {
  return {
    ui: {
      /**
       * Shown on a button for adding additional items.
       */
      add: () => i18n.t('Add'),
      /**
       * Shown when a button to remove items is visible.
       */
      remove: () => i18n.t('Remove'),
      /**
       * Shown when there are multiple items to remove at the same time.
       */
      removeAll: () => i18n.t('Remove all'),
      /**
       * Shown when all fields are not filled out correctly.
       */
      incomplete: () =>
        i18n.t('Sorry, not all fields are filled out correctly.'),
      /**
       * Shown in a button inside a form to submit the form.
       */
      submit: () => i18n.t('Submit'),
      /**
       * Shown when no files are selected.
       */
      noFiles: () => i18n.t('No file chosen.'),
      /**
       * Shown on buttons that move fields up in a list.
       */
      moveUp: () => i18n.t('Move up'),
      /**
       * Shown on buttons that move fields down in a list.
       */
      moveDown: () => i18n.t('Move down'),
      /**
       * Shown when something is actively loading.
       */
      isLoading: () => i18n.t('Loading…'),
      /**
       * Shown when there is more to load.
       */
      loadMore: () => i18n.t('Load more'),
    },

    validation: {
      /**
       * The value is not an accepted value.
       * @see {@link https://docs.formkit.com/essentials/validation#accepted}
       */
      accepted({ name }) {
        /* <i18n case="Shown when the user-provided value is not a valid 'accepted' value."> */
        return i18n.t('Please accept the %s.', name)
        /* </i18n> */
      },

      /**
       * The value is not letter and/or spaces
       * @see {@link https://docs.formkit.com/essentials/validation#alpha-spaces}
       */
      alpha_spaces() {
        /* <i18n case="Shown when the user-provided value contains non-alphabetical and non-space characters."> */
        return i18n.t('This field can only contain letters and spaces.')
        /* </i18n> */
      },

      /**
       * The date is not after
       * @see {@link https://docs.formkit.com/essentials/validation#date-after}
       */
      date_after({ args }) {
        if (Array.isArray(args) && args.length) {
          /* <i18n case="Shown when the user-provided date is not after the date supplied to the rule."> */
          return i18n.t(
            'This field must have a value that is after %s.',
            i18n.date(args[0]),
          )
          /* </i18n> */
        }
        /* <i18n case="Shown when the user-provided date is not after today's date, since no date was supplied to the rule."> */
        return i18n.t('This field must have a value that is in the future.')
        /* </i18n> */
      },

      /**
       * The value is not a letter.
       * @see {@link https://docs.formkit.com/essentials/validation#alpha}
       */
      alpha() {
        /* <i18n case="Shown when the user-provided value contains non-alphabetical characters."> */
        return i18n.t('This field can only contain alphabetical characters.')
        /* </i18n> */
      },

      /**
       * The value is not alphanumeric
       * @see {@link https://docs.formkit.com/essentials/validation#alphanumeric}
       */
      alphanumeric() {
        /* <i18n case="Shown when the user-provided value contains non-alphanumeric characters."> */
        return i18n.t('This field can only contain letters and numbers.')
        /* </i18n> */
      },

      /**
       * The date is not before
       * @see {@link https://docs.formkit.com/essentials/validation#date-before}
       */
      date_before({ args }) {
        if (Array.isArray(args) && args.length) {
          /* <i18n case="Shown when the user-provided date is not before the date supplied to the rule."> */
          return i18n.t(
            'This field must have a value that is before %s.',
            i18n.date(args[0]),
          )
          /* </i18n> */
        }
        /* <i18n case="Shown when the user-provided date is not before today's date, since no date was supplied to the rule."> */
        return i18n.t('This field must have a value that is in the past.')
        /* </i18n> */
      },

      /**
       * The value is not between two numbers
       * @see {@link https://docs.formkit.com/essentials/validation#between}
       */
      between({ args }) {
        if (Number.isNaN(args[0]) || Number.isNaN(args[1])) {
          /* <i18n case="Shown when any of the arguments supplied to the rule were not a number."> */
          return i18n.t(
            "This field was configured incorrectly and can't be submitted.",
          )
          /* </i18n> */
        }

        const [first, second] = order(args[0], args[1])

        /* <i18n case="Shown when the user-provided value is not between two numbers."> */
        return i18n.t(
          'This field must have a value that is between %s and %s.',
          first,
          second,
        )
        /* </i18n> */
      },

      /**
       * The confirmation field does not match
       * @see {@link https://docs.formkit.com/essentials/validation#confirm}
       */
      confirm() {
        /* <i18n case="Shown when the user-provided value does not equal the value of the matched input."> */
        return i18n.t("This field doesn't correspond to the expected value.")
        /* </i18n> */
      },

      /**
       * The value is not a valid date
       * @see {@link https://docs.formkit.com/essentials/validation#date-format}
       */
      date_format({ args }) {
        if (Array.isArray(args) && args.length) {
          /* <i18n case="Shown when the user-provided date does not satisfy the date format supplied to the rule."> */
          return i18n.t(
            'This field isn\'t a valid date, please use the format "%s".',
            args[0],
          )
          /* </i18n> */
        }
        /* <i18n case="Shown when no date argument was supplied to the rule."> */
        return i18n.t(
          "This field was configured incorrectly and can't be submitted.",
        )
        /* </i18n> */
      },

      /**
       * Is not within expected date range
       * @see {@link https://docs.formkit.com/essentials/validation#date-between}
       */
      date_between({ args }) {
        /* <i18n case="Shown when the user-provided date is not between the start and end dates supplied to the rule. "> */
        return i18n.t(
          'This field must have a value that is between %s and %s.',
          i18n.date(args[0]),
          i18n.date(args[1]),
        )
        /* </i18n> */
      },

      /**
       * Shown when the user-provided value is not a valid email address.
       * @see {@link https://docs.formkit.com/essentials/validation#email}
       */
      email: i18n.t('Please enter a valid email address.'),

      /**
       * Does not end with the specified value
       * @see {@link https://docs.formkit.com/essentials/validation#ends-with}
       */
      ends_with({ args }) {
        /* <i18n case="Shown when the user-provided value does not end with the substring supplied to the rule."> */
        return i18n.t(
          'This field doesn\'t end with "%s".',
          commaSeparatedList(args),
        )
        /* </i18n> */
      },

      /**
       * Is not an allowed value
       * @see {@link https://docs.formkit.com/essentials/validation#is}
       */
      is() {
        /* <i18n case="Shown when the user-provided value is not one of the values supplied to the rule."> */
        return i18n.t("This field doesn't contain an allowed value.")
        /* </i18n> */
      },

      /**
       * Does not match specified length
       * @see {@link https://docs.formkit.com/essentials/validation#length}
       */
      length({ args: [first = 0, second = Infinity] }) {
        const min = Number(first) <= Number(second) ? first : second
        const max = Number(second) >= Number(first) ? second : first
        if (min === 1 && max === Infinity) {
          /* <i18n case="Shown when the length of the user-provided value is not at least one character."> */
          return i18n.t('This field must contain at least one character.')
          /* </i18n> */
        }
        if (min === 0 && max) {
          /* <i18n case="Shown when first argument supplied to the rule is 0, and the user-provided value is longer than the max (the 2nd argument) supplied to the rule."> */
          return i18n.t(
            'This field must not contain more than %s characters.',
            max,
          )
          /* </i18n> */
        }
        if (min && max === Infinity) {
          /* <i18n case="Shown when the length of the user-provided value is less than the minimum supplied to the rule and there is no maximum supplied to the rule."> */
          return i18n.t('This field must contain at least %s characters.', min)
          /* </i18n> */
        }
        /* <i18n case="Shown when the length of the user-provided value is between the two lengths supplied to the rule."> */
        return i18n.t(
          'This field must contain between %s and %s characters.',
          min,
          max,
        )
        /* </i18n> */
      },

      /**
       * Value is not a match
       * @see {@link https://docs.formkit.com/essentials/validation#matches}
       */
      matches() {
        /* <i18n case="Shown when the user-provided value does not match any of the values or RegExp patterns supplied to the rule. "> */
        return i18n.t("This field doesn't contain an allowed value.")
        /* </i18n> */
      },

      /**
       * Exceeds maximum allowed value
       * @see {@link https://docs.formkit.com/essentials/validation#max}
       */
      max({ node: { value }, args }) {
        if (Array.isArray(value)) {
          /* <i18n case="Shown when the length of the array of user-provided values is longer than the max supplied to the rule."> */
          return i18n.t("This field can't have more than %s entries.", args[0])
          /* </i18n> */
        }
        /* <i18n case="Shown when the user-provided value is greater than the maximum number supplied to the rule."> */
        return i18n.t(
          'This field must have a value that is at most %s.',
          args[0],
        )
        /* </i18n> */
      },

      /**
       * The (field-level) value does not match specified mime type
       * @see {@link https://docs.formkit.com/essentials/validation#mime}
       */
      mime({ args }) {
        if (!args[0]) {
          /* <i18n case="Shown when no file formats were supplied to the rule."> */
          return i18n.t('No file formats allowed.')
          /* </i18n> */
        }
        /* <i18n case="Shown when the mime type of user-provided file does not match any mime types supplied to the rule."> */
        return i18n.t('This field must be of the type "%s".', args[0])
        /* </i18n> */
      },

      /**
       * Does not fulfill minimum allowed value
       * @see {@link https://docs.formkit.com/essentials/validation#min}
       */
      min({ node: { value }, args }) {
        if (Array.isArray(value)) {
          /* <i18n case="Shown when the length of the array of user-provided values is shorter than the min supplied to the rule."> */
          return i18n.t("This field can't have less than %s entries.", args[0])
          /* </i18n> */
        }
        /* <i18n case="Shown when the user-provided value is less than the minimum number supplied to the rule."> */
        return i18n.t(
          'This field must have a value that is at least %s.',
          args[0],
        )
        /* </i18n> */
      },

      /**
       * Is not an allowed value
       * @see {@link https://docs.formkit.com/essentials/validation#not}
       */
      not({ node: { value } }) {
        /* <i18n case="Shown when the user-provided value matches one of the values supplied to (and thus disallowed by) the rule."> */
        return i18n.t(
          'This field can\'t contain the value "%s".',
          value as string,
        )
        /* </i18n> */
      },

      /**
       *  Is not a number
       * @see {@link https://docs.formkit.com/essentials/validation#number}
       */
      number() {
        /* <i18n case="Shown when the user-provided value is not a number."> */
        return i18n.t('This field must contain a number.')
        /* </i18n> */
      },

      /**
       * Required field.
       * @see {@link https://docs.formkit.com/essentials/validation#required}
       */
      required() {
        /* <i18n case="Shown when a user does not provide a value to a required input."> */
        return i18n.t('This field is required.')
        /* </i18n> */
      },

      /**
       * Does not start with specified value
       * @see {@link https://docs.formkit.com/essentials/validation#starts-with}
       */
      starts_with({ args }) {
        /* <i18n case="Shown when the user-provided value does not start with the substring supplied to the rule."> */
        return i18n.t(
          'This field doesn\'t start with "%s".',
          commaSeparatedList(args),
        )
        /* </i18n> */
      },

      /**
       * Is not a url
       * @see {@link https://docs.formkit.com/essentials/validation#url}
       */
      url() {
        /* <i18n case="Shown when the user-provided value is not a valid url."> */
        return i18n.t('Please include a valid url.')
        /* </i18n> */
      },
    },
  }
}

export default loadLocales
