<?php

include_once( 'field_validators.php' );
$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/etc/config.ini', true);

// strings to be used in the input form starting with the date
$dt = (new DateTime('now'))->sub( new DateInterval('PT3H') ); // 3 hours in the past because it sucks typing something in at 1:00 a.m. and having last days date as default
$date = $dt->format("Y-m-d");
// error messages
$date_error = $quantity_error = '';
// info message at the end
$info_message = '';

// Handle posted input
if ( !empty($_POST["calories_entries_input_form_submit"]) )
{
    $mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);
    if ($mysqli->connect_errno)
    {
        die( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error);
    }

    $date = $_POST["date"];
    $item_id = $_POST["item_id"];
    $quantity = $_POST["quantity"];
    
    // Validierung
    $valid = True;
    // date validieren
    $result = validate_date($date);
    $valid = $valid && $result["valid"]; 
    $date_error = $result["error"];
    // quantity Validieren
    $result = validate_nonnegative_balance($quantity);
    $valid = $valid && $result["valid"]; 
    $quantity_error = $result["error"];

    if($valid)
    {
        $query = "INSERT INTO calories_entries
            (date, item_id, quantity)
            VALUES
            (?,?,?)";

        /* create a prepared statement */
        if (! $stmt = $mysqli->prepare($query)) {
            die( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* bind parameters for markers */
        if (! $stmt->bind_param("sid", $date, $item_id, $quantity) ) {
            die( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* execute query */
        if (! $stmt->execute() ) {
            die( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* close statement */
        $stmt->close();

        $info_message = "<p class=\"smallinfo\">Zeile<br>('$date', '$item_id', '$quantity')<br>in calories_items eingefügt.</p>";
    }

    $mysqli->close();
}

// calories_entries input form


// output the form
$form = '
    <h2>Mahlzeit eingeben</h2>

    <form action="%s" method="post">
    <ul>
        <li>
            <label for="date">Datum:</label>
            <input type="date" name="date" value="%s" placeholder="%2$s" required />
            %s
        </li>
        <li>
            <label for="item_id">Artikel:</label>
            <select name="item_id">%s</select>
        </li>
        <li>
            <label for="quantity">Menge:</label>
            <input type="number" step="0.01" name="quantity" required />
            <span class="form_hint">Format: \d+(\.\d{1,2})?</span>
            %s
        </li>
    </ul>
    <input class="form_button" type="submit" name="calories_entries_input_form_submit" value="Speichern" />
    %s
    </form>
    ';

// Get a list of input items for the drop down menu 
$mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);
if ($mysqli->connect_errno)
{
    die( "Failed to connect to MySQL: (" . mysqli_connect_error() . ") " . $mysqli->connect_error );
}
if (! $result = $mysqli->query("SELECT id, name, unit, kcal_per_unit FROM calories_items ORDER BY name ASC")) {
    die( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
}

$item_options = '';
while( $row = $result->fetch_assoc() ) {
    $item_options = $item_options . '<option value="' . $row["id"] . '">' . $row["name"] . ' (' .$row["kcal_per_unit"] . 'kcal/' . $row["unit"] . ')' . '</option>';
}

$mysqli->close();

echo sprintf($form, htmlspecialchars($_SERVER["PHP_SELF"]), $date, $date_error, $item_options, $quantity_error, $info_message);
?>
