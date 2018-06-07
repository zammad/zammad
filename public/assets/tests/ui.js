// date picker timezone conversion for display
test("date picker", function() {
  Date.prototype.getTimezoneOffset2 = Date.prototype.getTimezoneOffset
  Date.prototype.getTimezoneOffset = function() { return -360 }

  obj_date_time = {
    name: 'test',
    value: '2018-04-06T20:45:00.000Z'
  }

  el_date_time = App.UiElement.datetime.render(obj_date_time)

  date_time_parsed = new Date(Date.parse(obj_date_time.value))
  date_time_input = el_date_time.find('.js-datepicker').datepicker('getDate')
  equal(date_time_parsed.getDate(), date_time_input.getDate(), 'datetime matching day')

  obj_date = {
    name: 'test',
    value: '2018-06-06'
  }

  el_date = App.UiElement.date.render(obj_date)

  date_parsed = new Date(Date.parse(obj_date.value))
  date_input = el_date.find('.js-datepicker').datepicker('getUTCDate')
  equal(date_parsed.getDate(), date_input.getDate(), 'date matching day')

  Date.prototype.getTimezoneOffset = Date.prototype.getTimezoneOffset2
  Date.prototype.getTimezoneOffset2 = undefined
})

// pretty date
test("check pretty date", function() {
  var current = new Date()
  // use date formatting as functions to make it more flexible
  prettyDateRelative(current, '', true, 'relative');
  prettyDateAbsolute(current, '', true, 'absolute');

  // past

  function prettyDateRelative(current, escalation, lng, type) {
    var result = App.PrettyDate.humanTime(current, escalation, lng, type);
    equal(result, 'just now', 'just now')

    result = App.PrettyDate.humanTime(current - 15000, escalation, lng, type);
    equal(result, 'just now', 'just now')

    result = App.PrettyDate.humanTime(current - 60000, escalation, lng, type);
    equal(result, '1 minute ago', '1 min ago')

    result = App.PrettyDate.humanTime(current - (2 * 60000), escalation, lng, type);
    equal(result, '2 minutes ago', '2 min ago')

    result = App.PrettyDate.humanTime(current - (60000 * 60), escalation, lng, type);
    equal(result, '1 hour ago', '1 hour')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 2), escalation, lng, type);
    equal(result, '2 hours ago', '2 hours')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 2.5), escalation, lng, type);
    equal(result, '2 hours 30 minutes ago', '2.5 hours')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 12.5), escalation, lng, type);
    equal(result, '12 hours ago', '12.5 hours')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24), escalation, lng, type);
    equal(result, '1 day ago', '1 day')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2), escalation, lng, type);
    equal(result, '2 days ago', '2 days')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2) - (60000 * 5), escalation, lng, type);
    equal(result, '2 days ago', '2 days')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2.5), escalation, lng, type);
    equal(result, '2 days 12 hours ago', '2.5 days')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2.5) - (60000 * 5), escalation, lng, type);
    equal(result, '2 days 12 hours ago', '2.5 days')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 10.5), escalation, lng, type);
    var pastDate = new Date(current - (60000 * 60 * 24 * 10.5))
    var dd = pastDate.getDate();
    if(dd<10) {
        dd = '0' + dd
    }
    var mm = pastDate.getMonth() + 1;
    if(mm<10) {
        mm = '0' + mm
    }
    var yyyy = pastDate.getFullYear();
    // mm/dd/yyyy
    equal(result, mm+'/'+dd+'/'+yyyy, '10.5 days')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 30), escalation, lng, type);
    var pastDate = new Date(current - (60000 * 60 * 24 * 30))
    var dd = pastDate.getDate();
    if(dd<10) {
        dd = '0' + dd
    }
    var mm = pastDate.getMonth() + 1;
    if(mm<10) {
        mm = '0' + mm
    }
    var yyyy = pastDate.getFullYear();
    // mm/dd/yyyy
    equal(result, mm+'/'+dd+'/'+yyyy, '30 days')

    // future
    current = new Date()
    result = App.PrettyDate.humanTime(current, escalation, lng, type);
    equal(result, 'just now', 'just now')

    result = App.PrettyDate.humanTime(current.getTime() + 55000, escalation, lng, type);
    equal(result, 'just now', 'just now')

    result = App.PrettyDate.humanTime(current.getTime() + 65000, escalation, lng, type);
    equal(result, 'in 1 minute', 'in 1 min')

    result = App.PrettyDate.humanTime(current.getTime() + (2 * 65000), escalation, lng, type);
    equal(result, 'in 2 minutes', 'in 2 min')

    result = App.PrettyDate.humanTime(current.getTime() + (60500 * 60), escalation, lng, type);
    equal(result, 'in 1 hour', 'in 1 hour')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 2), escalation, lng, type);
    equal(result, 'in 2 hours', 'in 2 hours')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 2.5), escalation, lng, type);
    equal(result, 'in 2 hours 30 minutes', 'in 2.5 hours')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24), escalation, lng, type) ;
    equal(result, 'in 1 day', 'in 1 day')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 2), escalation, lng, type);
    equal(result, 'in 2 days', 'in 2 days')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 2.5), escalation, lng, type);
    equal(result, 'in 2 days 12 hours', 'in 2.5 days')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 5.5), escalation, lng, type);
    equal(result, 'in 5 days 12 hours', 'in 30.5 days')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 30.5), escalation, lng, type);
    equal(result, 'in 30 days', 'in 30.5 days')

  };

  function prettyDateAbsolute(current, escalation, lng, type) {

    var result = App.PrettyDate.humanTime(current, escalation, lng, type);
    equal(result, 'just now', 'just now') // by defaul < 1 min is just now

    result = App.PrettyDate.humanTime(current - 15000, escalation, lng, type);
    equal(result, 'just now', 'just now') // by default < 1 min is just now

    result = App.PrettyDate.humanTime(current - 60000, escalation, lng, type);
    diff = 60
    equal(result, getAbsolute(new Date(current - 60000), diff), '1 min ago')

    result = App.PrettyDate.humanTime(current - (2 * 60000), escalation, lng, type);
    diff = 2 * 60
    equal(result, getAbsolute(new Date(current - (2 * 60000)), diff), '2 min ago')

    result = App.PrettyDate.humanTime(current - (60000 * 60), escalation, lng, type);
    diff = 60 * 60
    equal(result, getAbsolute(new Date(current - (60000 * 60)), diff), '1 hour')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 2), escalation, lng, type);
    diff = 60 * 60 * 2
    equal(result, getAbsolute(new Date(current - (60000 * 60 * 2)), diff), '2 hours')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 2.5), escalation, lng, type);
    diff = 60 * 60 * 2.5
    equal(result, getAbsolute(new Date(current - (60000 * 60 * 2.5)), diff), '2.5 hours')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 12.5), escalation, lng, type);
    diff = 60 * 60 * 12.5
    equal(result, getAbsolute(new Date(current - (60000 * 60 * 12.5)), diff), '12.5 hours')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24), escalation, lng, type);
    diff = 60 * 60 * 25
    equal(result, getAbsolute(new Date(current - (60000 * 60 * 24)), diff), '1 day')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2), escalation, lng, type);
    diff = 60 * 60 * 25 * 2
    equal(result, getAbsolute(new Date(current - (60000 * 60 * 24 * 2)), diff), '2 days')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2) - (60000 * 5), escalation, lng, type);
    diff = (60 * 60 * 24 * 2) - (60 * 5)
    equal(result, getAbsolute(new Date(current - (60000 * 60 * 24 * 2) - (60000 * 5)), diff), '2 days')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2.5), escalation, lng, type);
    diff = (60 * 60 * 24 * 2.5)
    equal(result, getAbsolute(new Date(current - (60000 * 60 * 24 * 2.5)), diff), '2.5 days')

    result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2.5) - (60000 * 5), escalation, lng, type);
    diff = (60 * 60 * 24 * 2.5) - (60 * 5)
    equal(result, getAbsolute(new Date(current - (60000 * 60 * 24 * 2.5) - (60000 * 5)), diff), '2.5 days')

    // future
    current = new Date()
    result = App.PrettyDate.humanTime(current, escalation, lng, type);
    equal(result, 'just now', 'just now') // no change, because < 1 min = just now

    result = App.PrettyDate.humanTime(current.getTime() + 55000, escalation, lng, type);
    equal(result, 'just now', 'just now') // no change, because < 1 min = just now

    result = App.PrettyDate.humanTime(current.getTime() + 65000, escalation, lng, type);
    diff = 60
    equal(result, getAbsolute(new Date(current.getTime() + 65000), diff), 'in 1 min')

    result = App.PrettyDate.humanTime(current.getTime() + (2 * 65000), escalation, lng, type);
    diff = 2 * 60
    equal(result, getAbsolute(new Date(current.getTime() + (2 * 65000)), diff), 'in 2 min')

    result = App.PrettyDate.humanTime(current.getTime() + (60500 * 60), escalation, lng, type) ;
    diff = 60 * 60
    equal(result, getAbsolute(new Date(current.getTime() + (60500 * 60)), diff), 'in 1 hour')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 2), escalation, lng, type);
    diff = 60 * 60 * 2
    equal(result, getAbsolute(new Date(current.getTime() + (60050 * 60 * 2)), diff), 'in 2 hours')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 2.5), escalation, lng, type);
    diff = 60 * 60 * 2.5
    equal(result, getAbsolute(new Date(current.getTime() + (60050 * 60 * 2.5)), diff), 'in 2.5 hours')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24), escalation, lng, type);
    diff = 60 * 60 * 24
    equal(result, getAbsolute(new Date(current.getTime() + (60050 * 60 * 24)), diff), 'in 1 day')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 2), escalation, lng, type);
    diff = 60 * 60 * 24 * 2
    equal(result, getAbsolute(new Date(current.getTime() + (60050 * 60 * 24 * 2)), diff), 'in 2 days')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 2.5), escalation, lng, type);
    diff = 60 * 60 * 24 * 2.5
    equal(result, getAbsolute(new Date(current.getTime() + (60050 * 60 * 24 * 2.5)), diff), 'in 2.5 days')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 5.5), escalation, lng, type);
    diff = 60 * 60 * 24 * 5.5
    equal(result, getAbsolute(new Date(current.getTime() + (60050 * 60 * 24 * 5.5)), diff), 'in 30.5 days')

    result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 30.5), escalation, lng, type);
    diff = (60 * 60 * 24 * 30.5);
    equal(result, getAbsolute(new Date(current.getTime() + 60050 * 60 * 24 * 30.5), diff), 'in 30.5 days')

  };

  function getAbsolute(date, diff){
    weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    weekday = weekdays[date.getDay()];

    months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    month = months[date.getMonth()];

    // for less than 6 days
    // weekday HH::MM
    if (diff < (60 * 60 * 24 * 6))
      string = weekday + ' ' + date.getHours() + ':' + (date.getMinutes() < 10 ? '0':'') + date.getMinutes()
    else if (current.getYear() == date.getYear())
       string = weekday + ' ' + date.getDate() + '. ' + month + ' ' + date.getHours() + ":" + (date.getMinutes() < 10 ? '0':'') + date.getMinutes()
    else
       string = weekday + ' ' + date
    return string;
  }

});
