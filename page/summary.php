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
        <h1>Ausgaben</h1>
        <?php
            include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/spendings_input_form.php';
            include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/shoppinglist_input_form.php';
        ?>
    </div>

    <div class="box">
        <?php
            include $_SERVER["DOCUMENT_ROOT"] . '/generated_content/spendings/summary.html';
        ?>
    </div>

    <div class="small_box">
        <h1>Kalorien</h1>
        <?php
            include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/calories_entries_input_form.php';
            include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/calories_items_input_form.php';
        ?>
    </div>

    <div class="box">
        <?php
            include $_SERVER["DOCUMENT_ROOT"] . '/generated_content/calories/summary.html';
        ?>
    </div>

</div>

</body>
</html> 
