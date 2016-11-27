<?php
$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/config/config.ini', true);

if($_SERVER['REQUEST_METHOD'] === 'GET')
{
  // Get a list of input categories for the drop down menu 
  $mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);

  if ($mysqli->connect_errno)
  {
      die( "Failed to connect to MySQL: (" . mysqli_connect_error() . ") " . $mysqli->connect_error );
  }

  // Get list of categories
  $categories = array();
  if (! $result = $mysqli->query("SELECT category, priority from hoursofwork_categories ORDER BY priority ASC")) {
      die( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
  }
  for( $i = 0; $row = $result->fetch_assoc(); ++$i ) {
    $categories[$i] = array(
      "category" => $row["category"],
      "priority" => intval($row["priority"])
    );
  }
  $mysqli->close();


  // output the categories as JSON
  echo json_encode($categories);
} 
?>
