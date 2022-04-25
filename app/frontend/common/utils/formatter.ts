// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

/**
 * Creates an oxford-comma separated list of items.
 * @param args - items to list out
 * @param conjunction - in: x, y, and z "and" is the conjunction to use
 * @returns
 */
export function commaSeparatedList(
  items: string[],
  conjunction = 'or',
): string {
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
export function order(
  first: string | number,
  second: string | number,
): [smaller: number | string, larger: number | string] {
  return Number(first) >= Number(second) ? [second, first] : [first, second]
}

/**
 * Returns user's initials based on their first name, last name and email, if any present.
 * @param firstname - user's first name
 * @param lastname - user's last name
 * @param email - user's email address
 */
export function getInitials(
  firstname?: string,
  lastname?: string,
  email?: string,
) {
  if (firstname && lastname) {
    return firstname[0] + lastname[0]
  }

  return (firstname || lastname || email)?.substring(0, 2).toUpperCase() || '??'
}
