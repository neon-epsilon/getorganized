<?php

include_once( 'field_validators.php' );
$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/etc/config.ini', true);

// error strings to be used in the input form
$name_error = '';
$unit_error = '';
$kcal_per_unit_error = '';

// info message at the end
$info_message = '';

// Handle posted input
if ( !empty($_POST["calories_items_input_form_submit"]) )
{
    $mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);
    if ($mysqli->connect_errno)
    {
        die( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error);
    }

    $name = $_POST["name"];
    $unit = $_POST["unit"];
    $kcal_per_unit = $_POST["kcal_per_unit"];
    $category_id = $_POST["category_id"];
    
    // Validierung
    $valid = True;
    // name Validieren
    $result = validate_nonempty($name);
    $valid = $valid && $result["valid"]; 
    $name_error = $result["error"];
    // Unit Validieren
    $result = validate_nonempty($unit);
    $valid = $valid && $result["valid"]; 
    $unit_error = $result["error"];
    // kcal_per_unit Validieren
    $result = validate_balance($kcal_per_unit);
    $valid = $valid && $result["valid"]; 
    $kcal_per_unit_error = $result["error"];

    if($valid)
    {
        $query = "INSERT INTO calories_items
            (name, unit, kcal_per_unit, category_id)
            VALUES
            (?,?,?,?)";

        /* create a prepared statement */
        if (! $stmt = $mysqli->prepare($query)) {
            die( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* bind parameters for markers */
        if (! $stmt->bind_param("ssdi", $name, $unit, $kcal_per_unit, $category_id) ) {
            die( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* execute query */
        if (! $stmt->execute() ) {
            die( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* close statement */
        $stmt->close();

        $info_message = "<p class=\"smallinfo\">Zeile<br>('$name', '$unit', '$kcal_per_unit', '$category_id')<br>in calories_items eingefügt.</p>";
    }

    $mysqli->close();
}

// calories_items input form


// output the form
$form = '
    <h2>Speise oder Getränk eingeben</h2>

    <form action="%s" method="post">
    <ul>
        <li>
            <label for="name">Artikel:</label>
            <input type="text" name="name" required />
            %s
        </li>
        <li>
            <label for="unit">Portion:</label>
            <input type="text" name="unit" required />
            %s
        </li>
        <li>
            <label for="kcal_per_unit">kcal/Einheit:</label>
            <input type="number" step="0.01" name="kcal_per_unit" required />
            <span class="form_hint">Format: -?\d+</span>
            %s
        </li>
        <li>
            <label for="category_id">Kategorie:</label>
            <select name="category_id">%s</select>
        </li>
    </ul>
    <input class="form_button" type="submit" name="calories_items_input_form_submit" value="Speichern" />
    %s
    </form>
    ';

// Get a list of input categories for the drop down menu 
$mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);
if ($mysqli->connect_errno)
{
    die( "Failed to connect to MySQL: (" . mysqli_connect_error() . ") " . $mysqli->connect_error );
}
if (! $result = $mysqli->query("SELECT id, name FROM calories_categories ORDER BY priority ASC")) {
    die( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
}

$category_options = '';
while( $row = $result->fetch_assoc() ) {
    $category_options = $category_options . '<option value="' . $row["id"] . '">' . $row["name"] . '</option>';
}

$mysqli->close();

echo sprintf($form, htmlspecialchars($_SERVER["PHP_SELF"]), $name_error, $unit_error, $kcal_per_unit_error, $category_options, $info_message);
?>
