<?php

function bad_request($error_message)
{
  http_response_code(400);
  $response = array(
    "error" => $error_message
  );
  echo json_encode($response);
}

function method_not_allowed()
{
  http_response_code(405);
  $response = array(
    "error" => "Method not allowed."
  );
  echo json_encode($response);
}

function internal_server_error($error_message)
{
  http_response_code(500);
  $response = array(
    "error" => $error_message
  );
  echo json_encode($response);
}

function is_nonnegative_int($to_assert)
{
  if(!is_int($to_assert)) return false;
  if($to_assert < 0) return false;

  return true;
}

?>
