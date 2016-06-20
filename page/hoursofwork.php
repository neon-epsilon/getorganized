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
    include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/hoursofwork_input_form.php';
    ?>
    <?php
    include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/hoursofwork_delete_form.php';
    ?>
    </div>

    <div class="box">
    <?php
    include $_SERVER["DOCUMENT_ROOT"] . '/generated_content/hoursofwork/summary.html';
    ?>
    </div>

</div>

</body>
</html> 
