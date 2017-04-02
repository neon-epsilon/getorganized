<?php
include_once($_SERVER['DOCUMENT_ROOT'] . '/backend/lib/api_helper_functions.php' );
include_once($_SERVER['DOCUMENT_ROOT'] . '/backend/lib/field_validators.php' );

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
        die( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error);
    }


    $request_body = file_get_contents('php://input');
    $data = json_decode($request_body, true);


    $date = $data["date"];
    $amount = $data["amount"];
    $category = $data["category"];
    
    // Validierung
    $valid = True;
    // Datum validieren
    $result = validate_date($date);
    $valid = $valid && $result["valid"]; 
    $dateError = $result["error"];
    // Betrag Validieren
    $result = validate_nonnegative_balance($amount);
    $valid = $valid && $result["valid"]; 
    $amountError = $result["error"];

    if($valid)
    {
        $query = "INSERT INTO hoursofwork
            (date, amount, category)
            VALUES
            (?,?,?)";

        /* create a prepared statement */
        if (! $stmt = $mysqli->prepare($query)) {
            die( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* bind parameters for markers */
        if (! $stmt->bind_param("sds", $date, $amount, $category) ) {
            die( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* execute query */
        if (! $stmt->execute() ) {
            die( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* close statement */
        $stmt->close();

        $info_message = "<p class=\"smallinfo\">Zeile<br>('$date', '$amount', '$category')<br>in hoursofwork eingefügt.</p>";

        /* rebuild hoursofwork output */
        exec($_SERVER["DOCUMENT_ROOT"] . '/engine/reporting/build_hoursofwork_output.py > /dev/null 2> /dev/null &');
    }

    $mysqli->close();
}
else
{
  method_not_allowed();
}
?>
