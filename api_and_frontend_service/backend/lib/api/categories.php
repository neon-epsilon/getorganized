<?php
include_once($_SERVER['DOCUMENT_ROOT'] . '/backend/lib/api_helper_functions.php' );

if($_SERVER['REQUEST_METHOD'] === 'GET')
{
  $mysqli = get_mysqli();

  // Get list of categories
  $categories = array();
  if (! $result = $mysqli->query("SELECT category, priority from " . $db_name . "_categories ORDER BY priority ASC")) {
      internal_server_error( "Query failed: (" . $mysqli->connect_errno . ") " . $mysqli->error );
      exit;
  }
  for( $i = 0; $row = $result->fetch_assoc(); ++$i ) {
    $categories[$i] = array(
      "category" => $row["category"],
      "priority" => intval($row["priority"])
    );
  }
  $mysqli->close();


  // output the categories as JSON
  $response = array(
    "categories" => $categories
  );
  send_json($response);
} 
else
{
  method_not_allowed();
}
?>
