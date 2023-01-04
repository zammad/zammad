// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

/**
 * Creates an oxford-comma separated list of items.
 * @param args - items to list out
 * @param conjunction - in: x, y, and z "and" is the conjunction to use
 * @returns
 */
export const commaSeparatedList = (
  items: string[],
  conjunction = 'or',
): string => {
  return items.reduce((oxford, item, index) => {
    let oxfordList = oxford + item
    if (index <= items.length - 2 && items.length > 2) {
      oxfordList += ', '
    }
    if (index === items.length - 2) {
      oxfordList += `${items.length === 2 ? ' ' : ''}${conjunction} `
    }
    return oxfordList
  }, '')
}

/**
 * Orders two variables smallest to largest.
 * @param first - first argument
 * @param second - Second argument
 * @returns
 */
export const order = (
  first: string | number,
  second: string | number,
): [smaller: number | string, larger: number | string] => {
  return Number(first) >= Number(second) ? [second, first] : [first, second]
}

export const camelize = (str: string) => {
  return str.replace(/[_.-](\w|$)/g, (_, x) => x.toUpperCase())
}

export const toClassName = (str: string) => {
  return str.replace(
    /([a-z])([A-Z])/g,
    (_, lowerCase, upperCase) => `${lowerCase}::${upperCase}`,
  )
}

// app/assets/javascripts/app/lib/app_post/utils.coffee:230
export const phoneify = (phone: string) => {
  return phone.replace(/[^0-9,+,#,*]+/g, '').replace(/(.)\+/, '$1')
}

export const getFullName = (
  firstname?: Maybe<string>,
  lastname?: Maybe<string>,
): string => {
  const fullname = [firstname, lastname].filter(Boolean).join(' ')
  if (fullname === '-') return ''
  return fullname
}

/**
 * Returns user's initials based on their first name, last name and email, if any present.
 * @param firstname - user's first name
 * @param lastname - user's last name
 * @param email - user's email address
 */
export const getInitials = (
  firstname?: Maybe<string>,
  lastname?: Maybe<string>,
  email?: Maybe<string>,
) => {
  if (firstname && lastname) {
    return firstname[0] + lastname[0]
  }

  return (firstname || lastname || email)?.substring(0, 2).toUpperCase() || '??'
}

/**
 * Replaces code inside `#{obj.key}` with the value of the corresponding object.
 * @param template - string to replace
 * @param objects - reference object
 * @param encodeLink - should result be encoded
 */
export const replaceTags = (
  template: string,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  objects: any,
  encodeLink = false,
): string => {
  return template.replace(/#\{\s{0,2}(.+?)\s{0,2}\}/g, (index, key) => {
    const levels = key.replace(/<.+?>/g, '').split(/\./)
    let dataRef = objects
    for (const level of levels) {
      if (typeof dataRef === 'object' && level in dataRef) {
        dataRef = dataRef[level]
      } else {
        dataRef = ''
        break
      }
    }

    let value

    // if value is a function, execute function
    if (typeof dataRef === 'function') {
      value = dataRef()
    }
    // if value has content
    else if (dataRef != null && dataRef.toString) {
      // in case if we have a references object, check what datatype the attribute has
      // and e. g. convert timestamps/dates to browser locale
      // if dataRefLast?.constructor?.className
      //   localClassRef = App[dataRefLast.constructor.className]
      //   if localClassRef?.attributesGet
      //     attributes = localClassRef.attributesGet()
      //     if attributes?[level]
      //       if attributes[level]['tag'] is 'datetime'
      //         value = App.i18n.translateTimestamp(dataRef)
      //       else if attributes[level]['tag'] is 'date'
      //         value = App.i18n.translateDate(dataRef)

      // as fallback use value of toString()
      if (!value) value = dataRef.toString()
    } else {
      value = ''
    }

    if (value === '') value = '-'
    if (encodeLink) value = encodeURIComponent(value)

    return value
  })
}
