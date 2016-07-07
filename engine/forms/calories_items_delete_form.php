<?php
/* THIS IS A QUICK DRAFT THAT DOESN'T WORK YET */
$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/etc/config.ini', true);

// info message at the end
$info_message = '';

// Handle posted input
if ( !empty($_POST["calories_items_delete_form_submit"]) )
{
    $mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);
    if ($mysqli->connect_errno)
    {
        die( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error);
    }

    $item_id = $_POST["item_id"];
    
    $query = "DELETE FROM calories_items
        WHERE id=?";

    /* create a prepared statement */
    if (! $stmt = $mysqli->prepare($query)) {
        die( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
    }

    /* bind parameters for markers */
    if (! $stmt->bind_param("i", $item_id) ) {
        die( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
    }

    /* execute query */
    if (! $stmt->execute() ) {
        die( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
    }

    /* close statement */
    $stmt->close();

    $info_message = "<p class=\"smallinfo\">Eintrak mit id <br>" . $item_id . "<br>in calories_items gelöscht.</p>";

    $mysqli->close();
}

// calories_entries input form


// output the form
$form = '
    <h2>Speise oder Getränk löschen</h2>

    <form action="%s" method="post">
    <ul>
        <li>
            <label for="item_id">Artikel:</label>
            <select name="item_id">%s</select>
        </li>
    </ul>
    <input class="form_button" type="submit" name="calories_items_delete_form_submit" value="Speichern" />
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

echo sprintf($form, htmlspecialchars($_SERVER["PHP_SELF"]), $item_options, $info_message);
?>
