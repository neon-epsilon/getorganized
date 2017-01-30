<?php
$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/etc/config.ini', true);

// info message at the end
$info_message = '';

$mysqli = new mysqli($config['DB_shared']['host'],$config['DB_shared']['user'],$config['DB_shared']['password'],$config['DB_shared']['name']);

if ($mysqli->connect_errno)
{
    die( "Failed to connect to MySQL: (" . mysqli_connect_error() . ") " . $mysqli->connect_error );
}

// First, delete checked items from shoppinglist
// Look up their respective names, first, for the info message
if(!empty($_POST['names_to_delete'])){
    
    // put names together into a string for info mesage
    // and delete names
    $names_string = '';

    $query = "DELETE FROM shoppinglist
        WHERE name = ?";

    foreach($_POST['names_to_delete'] as $ntd){
        $names_string = $names_string . '"' .  $ntd . '"' . ",";

        /* create a prepared statement */
        if (! $stmt = $mysqli->prepare($query)) {
            die( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        /* bind parameters for markers */
        if (! $stmt->bind_param("s", $ntd) ) {
            die( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        /* execute query */
        if (! $stmt->execute() ) {
            die( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }
        /* close statement */
        $stmt->close();
    }
    $names_string = trim($names_string, ",");

    // create info message
    $info_message = "<p class=\"smallinfo\">Einträge <br>" . $names_string . "<br>in shoppinglist gelöscht.</p>";
}

// Get list of categories
$categories = array();
if (! $result = $mysqli->query("SELECT category FROM shoppinglist_categories ORDER BY priority ASC")) {
    die( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
}
for( $i = 0; $row = $result->fetch_assoc(); ++$i ) {
    $categories[$i] = $row["category"];
}

// Get the items on the shoppinglist for each category
$items = array();
foreach($categories as $category) {
    if (! $result = $mysqli->query("SELECT name FROM shoppinglist WHERE category = '" . $category . "'" ) ) {
        die( "query failed: (" . $mysqli->errno . ") " . $mysqli->error );
    }

    $items[$category] = array();
    for( $i = 0; $row = $result->fetch_assoc(); ++$i ) {
        $items[$category][$i] = $row;
    }
}

$mysqli->close();

// Print table with shoppinglist items
// The form is for the checkboxes which allow for deleting items from the list
echo '<form action="' . htmlspecialchars($_SERVER["PHP_SELF"]) . '" method="post">';

echo '<h2>Einkaufsliste</h2>';

echo '<table style="text-align: left;">';
echo '<tr>
    <th style="width: 1%;">Kategorie</th>
    <th>Artikel</th>
    <th style="width: 1%;"></th>
    </tr>';

foreach($categories as $category) {
    for( $i = 0; $i < count($items[$category]); ++$i) {
        $row = $items[$category][$i];
        if($i == 0) $categoryoutput = '<strong>' . $category . '</strong>';
        else $categoryoutput = '';
        echo '<tr>';
        echo '<td>' . $categoryoutput . '</td><td>' . $row["name"] . '</td>';
        echo '<td><input type="checkbox" name="names_to_delete[]" value="' . $row["name"] . '"></td>';
        echo '</tr>';
    }
}

echo "</table>";
echo '<input class="form_button" type="submit" name="shoppinglist_delete_submit" value="Löschen"/>';
// Print info message if input was succesful
echo $info_message;
echo '</form>';
?> 
