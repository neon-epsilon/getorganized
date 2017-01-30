<?php

include_once( 'field_validators.php' );
$config = parse_ini_file($_SERVER['DOCUMENT_ROOT'] . '/etc/config.ini', true);

// strings to be used in the input form
$nameError = '';

// info message at the end
$info_message = '';

// Handle posted input
if ( !empty($_POST["shoppinglist_input_form_submit"]) )
{
    $mysqli = new mysqli($config['DB_shared']['host'],$config['DB_shared']['user'],$config['DB_shared']['password'],$config['DB_shared']['name']);

    if ($mysqli->connect_errno)
    {
        die( "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error);
    }

    $name = $_POST["name"];
    $category = $_POST["category"];
    
    // Validierung
    $valid = True;
    // Name Validieren
    $result = validate_nonempty($name);
    $valid = $valid && $result["valid"]; 
    $nameError = $result["error"];

    if($valid)
    {
        $query = "INSERT INTO shoppinglist
            (name, category)
            VALUES
            (?,?)";

        /* create a prepared statement */
        if (! $stmt = $mysqli->prepare($query)) {
            die( "Prepare failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* bind parameters for markers */
        if (! $stmt->bind_param("ss", $name, $category) ) {
            die( "Binding parameters failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* execute query */
        if (! $stmt->execute() ) {
            die( "Execute failed: (" . $mysqli->errno . ") " . $mysqli->error);
        }

        /* close statement */
        $stmt->close();

        $info_message = "<p class=\"smallinfo\">Zeile<br>('$name', '$category')<br>in shoppinglist eingefügt.</p>";
    }

    $mysqli->close();
}

// shoppinglist input form

// Get a list of input categories for the drop down menu 
$mysqli = new mysqli($config['DB_shared']['host'],$config['DB_shared']['user'],$config['DB_shared']['password'],$config['DB_shared']['name']);

if ($mysqli->connect_errno)
{
    die( "Failed to connect to MySQL: (" . mysqli_connect_error() . ") " . $mysqli->connect_error );
}

// Get list of categories
$categories = array();
if (! $result = $mysqli->query("SELECT category FROM shoppinglist_categories ORDER BY priority ASC")) {
    die( "Query failed: (" . $mysqli->errno . ") " . $mysqli->error );
}
for( $i = 0; $row = $result->fetch_assoc(); ++$i ) {
    $categories[$i] = $row["category"];
}
$mysqli->close();


// output the form
$form = '
    <h2>Einkäufe eingeben</h2>

    <form action="%s" method="post">
    <ul>
        <li>
            <label for="name">Artikel:</label>
            <input type="text" name="name" required />
            %s
        </li>
        <li>
            <label for="category">Kategorie:</label>
            <select name="category">%s</select>
        </li>
    </ul>
    <input class="form_button" type="submit" name="shoppinglist_input_form_submit" value="Speichern" />
    %s
    </form>
    '; // to be filled out with: form-action, date-default-value, date-error, amount-error, list-of-categories, info-message

// items for drop-down menu for category
$categoryOptions = '';
foreach ($categories as $category) {
    $categoryOptions = $categoryOptions . '<option value="' . $category . '">' . $category . '</option>';
}

echo sprintf($form, htmlspecialchars($_SERVER["PHP_SELF"]), $nameError, $categoryOptions, $info_message);
?>
