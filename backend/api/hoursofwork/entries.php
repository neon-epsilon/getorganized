<?php
include_once($_SERVER['DOCUMENT_ROOT'] . '/backend/lib/api_helper_functions.php' );
include_once($_SERVER['DOCUMENT_ROOT'] . '/backend/lib/validators.php' );

$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/config/config.ini', true);

// Handle posted input
if($_SERVER['REQUEST_METHOD'] === 'GET')
{
  $request_body = file_get_contents('php://input');
  $data = json_decode($request_body, true);

  $start = $data["start"];
  $limit = $data["limit"];
  if($start === NULL) $start = 0;
  if($limit === NULL) $limit = 10;

  if(! is_nonnegative_int($start))
  {
    bad_request("Parameter 'start' is of wrong type.");
    exit;
  }
  if(! is_nonnegative_int($limit))
  {
    bad_request("Parameter 'limit' is of wrong type.");
    exit;
  }

  $mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);
  if ($mysqli->connect_errno)
  {
    internal_server_error( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error );
    exit;
  }

  // query for entries
  if (! $result = $mysqli->query("SELECT id, date, amount, category FROM hoursofwork ORDER BY id DESC LIMIT {$limit} OFFSET {$start}" ) ) {
    internal_server_error( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
    exit;
  }

  $items = array();
  for( $i = 0; $row = $result->fetch_assoc(); ++$i ) {
    // cast 'amount' field to right data type: float
    $row['amount'] = (float) $row['amount'];
    $items[$i] = $row;
  }

  $mysqli->close();

  echo json_encode($items);
}
elseif($_SERVER['REQUEST_METHOD'] === 'POST')
{
  $mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);
  if ($mysqli->connect_errno)
  {
      internal_server_error( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error );
      exit;
  }

  $request_body = file_get_contents('php://input');
  $data = json_decode($request_body, true);

  $date = $data["date"];
  $amount = $data["amount"];
  $category = $data["category"];

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
  if(! is_nonnegative_number($amount))
  {
    $valid = false;
    $invalid_fields[] = "amount";
  }
  // Kategorie validierenn
  // Get list of categories
  $categories = array();
  if (! $result = $mysqli->query("SELECT category, priority from hoursofwork_categories ORDER BY priority ASC")) {
      internal_server_error( "Query failed: (" . $mysqli->connect_errno . ") " . $mysqli->error );
      exit;
  }
  while( $row = $result->fetch_assoc() ) {
    $categories[] = $row["category"];
  }
  if(! in_array($category, $categories) )
  {
    $valid = false;
    $invalid_fields[] = "category";
  }

  if(! $valid)
  {
    http_response_code(400);
    $response = array(
      "error" => "Some fields are invalid.",
      "invalid fields" => $invalid_fields
    );
    echo json_encode($response);
  }
  else
  {
    $query = "INSERT INTO hoursofwork
      (date, amount, category)
      VALUES
      (?,?,?)";

    /* create a prepared statement */
    if (! $stmt = $mysqli->prepare($query)) {
      internal_server_error( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
      exit;
    }

    /* bind parameters for markers */
    if (! $stmt->bind_param("sds", $date, $amount, $category) ) {
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

    // Respond with id of new database entry
    $response = array(
      "id" => $mysqli->insert_id
    );
    echo json_encode($response);

    /* rebuild hoursofwork output */
    exec($_SERVER["DOCUMENT_ROOT"] . '/engine/reporting/build_hoursofwork_output.py > /dev/null 2> /dev/null &');
  }

  $mysqli->close();
}
elseif($_SERVER['REQUEST_METHOD'] === 'DELETE')
{
  $request_body = file_get_contents('php://input');
  /* Expect JSON-list of ids, that is, non-negative integers as input. */
  $ids = json_decode($request_body, true);

  // Validate ids.
  if($ids === NULL)
  {
    bad_request("Was expecting a JSON-list of ids (non-negative integers).");
    exit;
  }
  foreach($ids as $id)
  {
    if(! is_nonnegative_int($id))
    {
      bad_request("Was expecting a JSON-list of ids (non-negative integers).");
      exit;
    }
  }

  $mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);
  if ($mysqli->connect_errno)
  {
    internal_server_error( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error );
    exit;
  }

  // Check if rows are in table. If not, respond with not found ids.
  $not_found_ids = array();
  foreach($ids as $id)
  {
    if (! $result = $mysqli->query("SELECT id FROM hoursofwork WHERE id = {$id}" ) ) {
      internal_server_error( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
      exit;
    }

    if( $result->num_rows == 0)
    {
      $not_found_ids[] = $id;
    }
  }
  if(!empty($not_found_ids))
  {
    $response = array(
      "error" => "Some ids could not be found.",
      "not found ids" => $not_found_ids
    );
    http_response_code(404);
    echo json_encode($response);
    exit;
  }

  // Delete rows, respond 200.
  foreach($ids as $id)
  {
    if (! $mysqli->query("DELETE FROM hoursofwork WHERE id = {$id}" ) ) {
      internal_server_error( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
      exit;
    }
  }
}
else
{
  method_not_allowed();
}
?>
