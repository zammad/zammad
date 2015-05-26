<?

// check for ajax request
if (!empty($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) == 'xmlhttprequest') {
  file_put_contents('list.json', json_encode($_POST['list'], JSON_PRETTY_PRINT));
  exit();
}

?>