<?php
include_once($_SERVER['DOCUMENT_ROOT'] . '/backend/lib/api_helper_functions.php' );
include_once($_SERVER['DOCUMENT_ROOT'] . '/backend/lib/validators.php' );


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

  $mysqli = get_mysqli_shoppinglist();

  // query for entries
  if (! $result = $mysqli->query("SELECT id, name, category FROM shoppinglist_entries ORDER BY id DESC LIMIT {$limit} OFFSET {$start}" ) ) {
    internal_server_error( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
    exit;
  }

  $items = array();
  for( $i = 0; $row = $result->fetch_assoc(); ++$i ) {
    $items[$i] = $row;
    $items[$i]["id"] = (int) $items[$i]["id"];
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

  $name = $data["name"];
  $category = $data["category"];

  // Validierung
  $valid = true;
  $invalid_fields = array();
  // validate category
  // Get list of categories
  $mysqli = get_mysqli_shoppinglist();

  if (! $result = $mysqli->query("SELECT category, priority from shoppinglist_categories ORDER BY priority ASC")) {
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
    $mysqli = get_mysqli_shoppinglist();

    $query = "INSERT INTO shoppinglist_entries
      (name, category)
      VALUES
      (?,?)";

    /* create a prepared statement */
    if (! $stmt = $mysqli->prepare($query)) {
      internal_server_error( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
      exit;
    }

    /* bind parameters for markers */
    if (! $stmt->bind_param("ss", $name, $category) ) {
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
    send_json($response);

    $mysqli->close();

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

  $mysqli = get_mysqli_shoppinglist();

  // Check if rows are in table. If not, respond with not found ids.
  $not_found_ids = array();
  foreach($ids as $id)
  {
    if (! $result = $mysqli->query("SELECT id FROM shoppinglist_entries WHERE id = {$id}" ) ) {
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

  // Delete rows, respond 200 and a dummy JSON object
  $mysqli = get_mysqli_shoppinglist();

  foreach($ids as $id)
  {
    if (! $mysqli->query("DELETE FROM shoppinglist_entries WHERE id = {$id}" ) ) {
      internal_server_error( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
      exit;
    }
  }
  $mysqli->close();

  send_json( array(
    "ids" => $ids
  ));
}
else
{
  method_not_allowed();
}
?>
