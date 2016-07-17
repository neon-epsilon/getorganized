<?php

include_once( 'field_validators.php' );
$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/etc/config.ini', true);

// info message at the end
$info_message = '';

// Handle posted input
if ( !empty($_POST["calories_items_delete_form_submit"]) )
{
    $item_to_delete_id = intval($_POST["item_to_delete_id"]);
    $item_to_map_to_id = intval($_POST["item_to_map_to_id"]);

    $item_to_delete_kcal_per_unit = 0;
    $item_to_map_to_kcal_per_unit = 0;

    // Validierung
    $valid = True;
    if( $item_to_delete_id == $item_to_map_to_id) {
        $valid = False;
        $info_message = '<div class="error">Artikel können nicht gleich sein.</div>';
    }

    if($valid)
    {
        $mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);
        if ($mysqli->connect_errno)
        {
            die( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error);
        }

        // fetch kcal_per_unit for old and new item
        $query = "SELECT kcal_per_unit FROM calories_items WHERE id = ?";
        if (! $stmt = $mysqli->prepare($query)) {
            die( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        // old item
        if (! $stmt->bind_param("i", $item_to_delete_id) ) {
            die( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        if (! $stmt->execute() ) {
            die( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        if (! $stmt->bind_result($item_to_delete_kcal_per_unit) ) {
            die( "Binding result failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        if (! $stmt->fetch() ) {
            die( "Fetching result failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        // new item
        if (! $stmt->bind_param("i", $item_to_map_to_id) ) {
            die( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        if (! $stmt->execute() ) {
            die( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        if (! $stmt->bind_result($item_to_map_to_kcal_per_unit) ) {
            die( "Binding result failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        if (! $stmt->fetch() ) {
            die( "Fetching result failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        // close the prepared statement; if not, it thinks that we didn't fetch all desired data
        $stmt->close();

        // calculate factor to multiply the old quantity with
        $quantity_conversion_factor = $item_to_delete_kcal_per_unit / $item_to_map_to_kcal_per_unit;

        // update calories_entries
        $query = "UPDATE calories_entries SET item_id = ?, quantity = ? * quantity WHERE item_id = ?";
        $stmt = $mysqli->prepare($query);
        if (! $stmt ) {
            die( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        if (! $stmt->bind_param("idi", $item_to_map_to_id, $quantity_conversion_factor, $item_to_delete_id) ) {
            die( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        if (! $stmt->execute() ) {
            die( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        // delete old item
        $query = "DELETE FROM calories_items WHERE id = ?";
        if (! $stmt = $mysqli->prepare($query)) {
            die( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        if (! $stmt->bind_param("i", $item_to_delete_id) ) {
            die( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        if (! $stmt->execute() ) {
            die( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        $mysqli->close();
    }
}

// calories_items delete form

$form = '
    <h2>Artikel löschen</h2>

    <form action="%s" method="post">
    <ul>
        <li>
            <label for="item_to_delete_id">Artikel löschen:</label>
            <select name="item_to_delete_id">%s</select>
        </li>
        <li>
            <label for="item_to_map_to_id">Bestehende Einträge diesem Artikel zuordnen:</label>
            <select name="item_to_map_to_id">%s</select>
        </li>
    </ul>
    <input class="form_button" type="submit" name="calories_items_delete_form_submit" value="Löschen" />
    %s
    </form>
    ';

// Get a list of input categories for the drop down menu
$mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);
if ($mysqli->connect_errno)
{
    die( "Failed to connect to MySQL: (" . mysqli_connect_error() . ") " . $mysqli->connect_error );
}
if (! $result = $mysqli->query("SELECT id, name, unit, kcal_per_unit FROM calories_items ORDER BY name ASC")) {
    die( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
}

$options = '';
while( $row = $result->fetch_assoc() ) {
    $options = $options . '<option value="' . $row["id"] . '">' . $row["name"] . ' (' .$row["kcal_per_unit"] . 'kcal/' . $row["unit"] . ')' . '</option>';
}

$mysqli->close();

echo sprintf($form, htmlspecialchars($_SERVER["PHP_SELF"]), $options, $options, $info_message);
?>
