<?php

include_once( 'field_validators.php' );
$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/etc/config.ini', true);

// strings to be used in the input form starting with the date
$dt = (new DateTime('now'))->sub( new DateInterval('PT3H') ); // 3 hours in the past because it sucks typing something in at 1:00 a.m. and having last days date as default
$date = $dt->format("Y-m-d");
$dateError = $amountError = '';

// info message at the end
$info_message = '';

// Handle posted input
if ( !empty($_POST["workout_input_form_submit"]) )
{
    $mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);

    if ($mysqli->connect_errno)
    {
        die( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error);
    }

    $date = $_POST["date"];
    $amount = $_POST["amount"];
    $category = $_POST["category"];
    
    // Validierung
    $valid = True;
    // Datum validieren
    $result = validate_date($date);
    $valid = $valid && $result["valid"]; 
    $dateError = $result["error"];
    // Anzahl Validieren
    $result = validate_number($amount);
    $valid = $valid && $result["valid"]; 
    $amountError = $result["error"];

    if($valid)
    {
        $query = "INSERT INTO workout
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

        $info_message = "<p class=\"smallinfo\">Zeile<br>('$date', '$amount', '$category')<br>in workout eingefügt.</p>";

        /* rebuild workout output */
        exec('cd ' . $_SERVER["DOCUMENT_ROOT"] .' && ' . $_SERVER["DOCUMENT_ROOT"] . '/engine/reporting/build_workout_output.py > /dev/null 2> /dev/null &');
    }

    $mysqli->close();
}

// workout input form

// Get a list of input categories for the drop down menu 
$mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);

if ($mysqli->connect_errno)
{
    die( "Failed to connect to MySQL: (" . mysqli_connect_error() . ") " . $mysqli->connect_error );
}

// Get list of categories
$categories = array();
if (! $result = $mysqli->query("SELECT category FROM workout_categories ORDER BY priority ASC")) {
    die( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
}
for( $i = 0; $row = $result->fetch_assoc(); ++$i ) {
    $categories[$i] = $row["category"];
}
$mysqli->close();


// output the form
$form = '
    <h2>Training eingeben</h2>

    <form action="%s" method="post">
    <ul>
        <li>
            <label for="date">Datum:</label>
            <input type="date" name="date" value="%s" placeholder="%2$s" required />
            %s
        </li>
        <li>
            <label for="amount">Betrag:</label>
            <input type="number" step="1" name="amount" required />
            <span class="form_hint">Format: \d+</span>
            %s
        </li>
        <li>
            <label for="category">Kategorie:</label>
            <select name="category">%s</select>
        </li>
    </ul>
    <input class="form_button" type="submit" name="workout_input_form_submit" value="Speichern" />
    %s
    </form>
    '; // to be filled out with: form-action, date-default-value, date-error, amount-error, list-of-categories, info-message

// items for drop-down menu for category
$categoryOptions = '';
foreach ($categories as $category) {
    $categoryOptions = $categoryOptions . '<option value="' . $category . '">' . $category . '</option>';
}

echo sprintf($form, htmlspecialchars($_SERVER["PHP_SELF"]), $date, $dateError, $amountError, $categoryOptions, $info_message);
?>
