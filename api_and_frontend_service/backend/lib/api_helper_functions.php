<?php

$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/config/config.ini', true);

$charting_service_address = getenv('CHARTING_SERVICE_ADDRESS') ?: "charting-service";
$charting_service_port = getenv('CHARTING_SERVICE_PORT') ?: "8000";

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

function generate_charts($chart_type, $timestamp_string)
{
  global $charting_service_address;
  global $charting_service_port;

  $charting_service_endpoint = "$charting_service_address:$charting_service_port/$chart_type/";
  $params = array('timestamp' => $timestamp_string);
  $uri = $charting_service_endpoint . "?" . http_build_query($params);

  $curl = curl_init($uri);
  curl_setopt($curl, CURLOPT_POST, true);
  curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
  $_response = curl_exec($curl);
  curl_close($curl);
}

?>
