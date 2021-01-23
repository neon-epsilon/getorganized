<?php

$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/config/config.ini', true);

function get_mysqli()
{
  global $config;

  $mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);

  if ($mysqli->connect_errno)
  {
      internal_server_error( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error );
      exit;
  }

  // Charset must be utf8, otherwise JSON serialization of data from db might fail.
  if( !$mysqli->set_charset("utf8mb4") )
  {
      internal_server_error( "Failed setting MySQL charset to utf8mb4: (" . $mysqli->connect_errno . ") " . $mysqli->error );
      exit;
  }

  return $mysqli;
}

function get_mysqli_shoppinglist()
{
  global $config;

  $mysqli = new mysqli($config['DB_shoppinglist']['host'],$config['DB_shoppinglist']['user'],$config['DB_shoppinglist']['password'],$config['DB_shoppinglist']['name']);

  if ($mysqli->connect_errno)
  {
      internal_server_error( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error );
      exit;
  }

  // Charset must be utf8, otherwise JSON serialization of data from db might fail.
  if( !$mysqli->set_charset("utf8mb4") )
  {
      internal_server_error( "Failed setting MySQL charset to utf8mb4: (" . $mysqli->connect_errno . ") " . $mysqli->error );
      exit;
  }

  return $mysqli;
}

function send_json($data)
{
  header('Content-Type: application/json');
  echo json_encode($data);
}

function bad_request($error_message)
{
  http_response_code(400);
  $response = array(
    "error" => $error_message
  );
  send_json($response);
}

function method_not_allowed()
{
  http_response_code(405);
  $response = array(
    "error" => "Method not allowed."
  );
  send_json($response);
}

function internal_server_error($error_message)
{
  http_response_code(500);
  $response = array(
    "error" => $error_message
  );
  send_json($response);
}

?>
