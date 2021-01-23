<?php
include_once($_SERVER['DOCUMENT_ROOT'] . '/backend/lib/api_helper_functions.php' );
include_once($_SERVER['DOCUMENT_ROOT'] . '/backend/lib/validators.php' );

$python = $_SERVER["DOCUMENT_ROOT"] . "/backend/virtualenv/bin/python";
$output_build_script = $_SERVER["DOCUMENT_ROOT"] . "/backend/reporting/build_" . $db_name . "_output.py";

if($_SERVER['REQUEST_METHOD'] === 'GET')
{
  $start = $_GET['start'];
  $limit = $_GET['limit'];

  if($start === NULL)
    $start = "0";
  else if(!ctype_digit($start))
  {
    bad_request("Parameter 'start' is not a non-negative integer.");
    exit;
  }

  if($limit === NULL)
    $limit = "10";
  else if(!ctype_digit($limit))
  {
    bad_request("Parameter 'limit' is not a non-negative integer.");
    exit;
  }


  $mysqli = get_mysqli();

  // query for entries
  if (! $result = $mysqli->query("SELECT id, date, amount, category, comment FROM " . $db_name . "_entries ORDER BY id DESC LIMIT {$limit} OFFSET {$start}" ) ) {
    internal_server_error( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
    exit;
  }

  $items = array();
  for( $i = 0; $row = $result->fetch_assoc(); ++$i ) {
    // cast 'amount' field to right data type: float
    $row['id'] = (int) $row['id'];
    $row['amount'] = (float) $row['amount'];
    $items[$i] = $row;
  }

  $mysqli->close();

  send_json( array(
    "entries" => $items
  ));
}
elseif($_SERVER['REQUEST_METHOD'] === 'POST')
{
  $request_body = file_get_contents('php://input');
  $data = json_decode($request_body, true);
  if($data === NULL)
  {
    bad_request("Could not decode JSON request.");
    exit;
  }

  $date = $data["date"];
  $amount = $data["amount"];
  $category = $data["category"];
  $comment = $data["comment"];

  if($comment === NULL) $comment = "";

  // Validierung
  $valid = true;
  $invalid_fields = array();
  // Datum validieren
  if(! is_date($date) )
  {
    $valid = false;
    $invalid_fields[] = "date";
  }
  // Betrag validieren
  if(! is_number($amount))
  {
    $valid = false;
    $invalid_fields[] = "amount";
  }
  // validate category
  // Get list of categories
  $mysqli = get_mysqli();

  if (! $result = $mysqli->query("SELECT category, priority from " . $db_name . "_categories ORDER BY priority ASC")) {
      internal_server_error( "Query failed: (" . $mysqli->connect_errno . ") " . $mysqli->error );
      exit;
  }
  $categories = array();
  while( $row = $result->fetch_assoc() ) {
    $categories[] = $row["category"];
  }
  $mysqli->close();
  if(! in_array($category, $categories) )
  {
    $valid = false;
    $invalid_fields[] = "category";
  }
  // validate comment
  if(! is_string($comment) )
  {
    $valid = false;
    $invalid_fields[] = "comment";
  }

  if(! $valid)
  {
    http_response_code(400);
    $response = array(
      "error" => "Some fields are invalid.",
      "invalid fields" => $invalid_fields
    );
    send_json($response);
  }
  else
  {
    $mysqli = get_mysqli();

    $query = "INSERT INTO " . $db_name . "_entries
      (date, amount, category, comment)
      VALUES
      (?,?,?,?)";

    /* create a prepared statement */
    if (! $stmt = $mysqli->prepare($query)) {
      internal_server_error( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
      exit;
    }

    /* bind parameters for markers */
    if (! $stmt->bind_param("sdss", $date, $amount, $category, $comment) ) {
      internal_server_error( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
      exit;
    }

    /* execute query */
    if (! $stmt->execute() ) {
      internal_server_error( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
      exit;
    }

    /* close statement */
    $stmt->close();

    $timestamp = microtime(true); //timestamp of generated charts

    /* Respond with id of new database entry */
    $response = array(
      "id" => $mysqli->insert_id,
      "timestamp" => $timestamp
    );
    send_json($response);

    $mysqli->close();

    /* rebuild output */
    exec($python . " " . $output_build_script . " " . strval($timestamp) . " > /dev/null 2> /dev/null &");
  }
}
elseif($_SERVER['REQUEST_METHOD'] === 'DELETE')
{
  /* Expect JSON-list of ids, that is, non-negative integers as input. */
  $request_body = file_get_contents('php://input');
  $data = json_decode($request_body, true);
  if($data === NULL)
  {
    bad_request("Could not decode JSON request.");
    exit;
  }

  $ids = $data["ids"];

  // Validate ids.
  if($ids === NULL)
  {
    bad_request("Was expecting a JSON-object of the form '{\"ids\": [int]}'");
    exit;
  }
  foreach($ids as $id)
  {
    if(! is_nonnegative_int($id))
    {
      bad_request("Was expecting a JSON-object of the form '{\"ids\": [int]}'");
      exit;
    }
  }

  $mysqli = get_mysqli();

  // Check if rows are in table. If not, respond with not found ids.
  $not_found_ids = array();
  foreach($ids as $id)
  {
    if (! $result = $mysqli->query("SELECT id FROM " . $db_name . "_entries WHERE id = {$id}" ) ) {
      internal_server_error( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
      exit;
    }

    if( $result->num_rows == 0)
    {
      $not_found_ids[] = $id;
    }
  }
  $mysqli->close();

  if(!empty($not_found_ids))
  {
    $response = array(
      "error" => "Some ids could not be found.",
      "not found ids" => $not_found_ids
    );
    http_response_code(404);
    send_json($response);
    exit;
  }

  // Delete rows, respond 200 and a JSON object with the timestamp of the new picture
  $mysqli = get_mysqli();

  foreach($ids as $id)
  {
    if (! $mysqli->query("DELETE FROM " . $db_name . "_entries WHERE id = {$id}" ) ) {
      internal_server_error( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
      exit;
    }
  }
  $mysqli->close();

  $timestamp = microtime(true); //timestamp of generated charts

  send_json( array(
    "ids" => $ids,
    "timestamp" => $timestamp
  ));

  /* rebuild output */
  exec($python . " " . $output_build_script . " " . strval($timestamp) . " > /dev/null 2> /dev/null &");
}
else
{
  method_not_allowed();
}
?>
