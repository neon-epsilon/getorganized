<?php

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
