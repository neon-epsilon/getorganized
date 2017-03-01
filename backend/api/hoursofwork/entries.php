<?php
include_once($_SERVER['DOCUMENT_ROOT'] . '/backend/forms/field_validators.php' );
$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/etc/config.ini', true);

// Handle posted input
if($_SERVER['REQUEST_METHOD'] === 'POST')
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
// Needs Error handling, status codes (200, 400), testing
}
?>
