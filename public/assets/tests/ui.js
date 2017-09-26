
// pretty date
test("check pretty date", function() {
  var current = new Date()

  // past
  var result = App.PrettyDate.humanTime(current);
  equal(result, 'just now', 'just now')

  result = App.PrettyDate.humanTime(current - 15000);
  equal(result, 'just now', 'just now')

  result = App.PrettyDate.humanTime(current - 60000);
  equal(result, '1 minute ago', '1 min ago')

  result = App.PrettyDate.humanTime(current - (2 * 60000));
  equal(result, '2 minutes ago', '2 min ago')

  result = App.PrettyDate.humanTime(current - (60000 * 60)) ;
  equal(result, '1 hour ago', '1 hour')

  result = App.PrettyDate.humanTime(current - (60000 * 60 * 2));
  equal(result, '2 hours ago', '2 hours')

  result = App.PrettyDate.humanTime(current - (60000 * 60 * 2.5));
  equal(result, '2 hours 30 minutes ago', '2.5 hours')

  result = App.PrettyDate.humanTime(current - (60000 * 60 * 12.5));
  equal(result, '12 hours ago', '12.5 hours')

  result = App.PrettyDate.humanTime(current - (60000 * 60 * 24)) ;
  equal(result, '1 day ago', '1 day')

  result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2));
  equal(result, '2 days ago', '2 days')

  result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2) - (60000 * 5));
  equal(result, '2 days ago', '2 days')

  result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2.5));
  equal(result, '2 days 12 hours ago', '2.5 days')

  result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 2.5) - (60000 * 5));
  equal(result, '2 days 12 hours ago', '2.5 days')

  result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 10.5));
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

  result = App.PrettyDate.humanTime(current - (60000 * 60 * 24 * 30));
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
  result = App.PrettyDate.humanTime(current);
  equal(result, 'just now', 'just now')

  result = App.PrettyDate.humanTime(current.getTime() + 55000);
  equal(result, 'just now', 'just now')

  result = App.PrettyDate.humanTime(current.getTime() + 65000);
  equal(result, 'in 1 minute', 'in 1 min')

  result = App.PrettyDate.humanTime(current.getTime() + (2 * 65000));
  equal(result, 'in 2 minutes', 'in 2 min')

  result = App.PrettyDate.humanTime(current.getTime() + (60500 * 60)) ;
  equal(result, 'in 1 hour', 'in 1 hour')

  result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 2));
  equal(result, 'in 2 hours', 'in 2 hours')

  result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 2.5));
  equal(result, 'in 2 hours 30 minutes', 'in 2.5 hours')

  result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24)) ;
  equal(result, 'in 1 day', 'in 1 day')

  result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 2));
  equal(result, 'in 2 days', 'in 2 days')

  result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 2.5));
  equal(result, 'in 2 days 12 hours', 'in 2.5 days')

  result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 5.5));
  equal(result, 'in 5 days 12 hours', 'in 30.5 days')

  result = App.PrettyDate.humanTime(current.getTime() + (60050 * 60 * 24 * 30.5));
  equal(result, 'in 30 days', 'in 30.5 days')

  // 



});
