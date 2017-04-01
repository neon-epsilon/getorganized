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

    <div class="box">
        <h1>Gemeinsame Einkaufsliste</h1>
        <?php
        include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/shoppinglist_input_form_shared.php';
        ?>
        <?php
        include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/shoppinglist_shared.php';
        ?>
    </div>

    <div class="box">
        <h1>Eigene Einkaufsliste</h1>
        <?php
        include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/shoppinglist_input_form.php';
        ?>
        <?php
        include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/shoppinglist.php';
        ?>
    </div>

</div>

</body>
</html> 
