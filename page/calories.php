<!DOCTYPE html>
<html>

<head>
<?php
include $_SERVER["DOCUMENT_ROOT"] . '/design/header.php';
?>
</head>

<body>

<?php
include $_SERVER["DOCUMENT_ROOT"] . '/design/menu.php';
?>

<div class="container">

    <div class="small_box">
    <h1>Eingabe</h1>
    <?php
        include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/calories_entries_input_form.php';
        include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/calories_items_input_form.php';
    ?>
    </div>

    <div class="small_box">
    <h1>Löschen</h1>
    <?php
        include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/calories_entries_delete_form.php';
        //include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/calories_items_delete_form.php';
    ?>
    </div>

</div>

</body>
</html> 
