class App.CustomerOrganizationAjaxSelect extends App.SearchableAjaxSelect
  cacheKey: =>
    customerId = @el.closest('form').find('input[name=customer_id]').val()
    return super if !customerId
    return "#{super}-customer-#{customerId}"

  ajaxAttributes: =>
    customerId = @el.closest('form').find('input[name=customer_id]').val()
    return super if !customerId

    user = App.User.find(customerId)
    return super if !user
    return super if user.allOrganizationIds().length < 1

    data = super
    data.data = JSON.stringify(query: @input.val() + '*', limit: @options.attribute.limit, ids: user.allOrganizationIds())
    return data
