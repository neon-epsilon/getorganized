<?php
$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/etc/config.ini', true);

// number of items to show on the delete form
$number_of_items = 7;

// prepare info message at the end
$info_message = '';

$mysqli = new mysqli($config['DB']['host'],$config['DB']['user'],$config['DB']['password'],$config['DB']['name']);

if ($mysqli->connect_errno)
{
    die( "Failed to connect to MySQL: (" . mysqli_connect_error() . ") " . $mysqli->connect_error );
}

// First, delete checked items
// Look up their respective ids first, for the info message
if(!empty($_POST['ids_to_delete'])){
    
    // put ids together into a string for info mesage
    // and delete ids
    $ids_string = '';

    $query = "DELETE FROM calories_entries
        WHERE id = ?";

    foreach($_POST['ids_to_delete'] as $itd){
        $ids_string = $ids_string . '"' .  $itd . '"' . ",";

        /* create a prepared statement */
        if (! $stmt = $mysqli->prepare($query)) {
            die( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        /* bind parameters for markers */
        if (! $stmt->bind_param("i", $itd) ) {
            die( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        /* execute query */
        if (! $stmt->execute() ) {
            die( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        /* close statement */
        $stmt->close();
    }
    $ids_string = trim($ids_string, ",");

    // create info message
    $info_message = "<p class=\"smallinfo\">Einträge <br>" . $ids_string . "<br>in calories_entries gelöscht.</p>";

    /* rebuild calories_entries output */
    exec($_SERVER["DOCUMENT_ROOT"] . '/engine/reporting/build_calories_output.py > /dev/null 2> /dev/null &');
}

// Get the last entries
if (! $result = $mysqli->query("SELECT a.id, a.date, b.name AS item, ROUND(a.quantity * b.kcal_per_unit) AS kcals FROM calories_entries a LEFT JOIN calories_items b ON a.item_id = b.id ORDER BY id DESC LIMIT {$number_of_items}" ) ) {
die( "query failed: (" . $mysqli->errno . ") " . $mysqli->error );
}

$items = array();
for( $i = 0; $row = $result->fetch_assoc(); ++$i ) {
    $items[$i] = $row;
}

$mysqli->close();

// Print table with shoppinglist items
// The form is for the checkboxes which allow for deleting items from the list
echo '<form action="' . htmlspecialchars($_SERVER["PHP_SELF"]) . '" method="post">';

echo '<h2>Letzte Einträge löschen</h2>';

echo '<table style="text-align: right;">';
echo '<tr>
    <th style="width: 1%;">Datum</th>
    <th>Artikel</th>
    <th>Kalorien</th>
    <th style="width: 1%;"></th>
    </tr>';

for( $i = 0; $i < count($items); ++$i) {
    $row = $items[$i];
    echo '<tr>';
    echo '<td>' . $row["date"] . '</td><td>' . $row["item"] . '</td><td>' . $row["kcals"] .'</td>';
    echo '<td><input type="checkbox" name="ids_to_delete[]" value="' . $row["id"] . '"></td>';
    echo '</tr>';
}

echo "</table>";
echo '<input class="form_button" type="submit" name="calories_entries_delete_submit" value="Löschen"/>';
// Print info message if input was succesful
echo $info_message;
echo '</form>';
?> 