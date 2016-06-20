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
    include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/workout_input_form.php';
    ?>
    <?php
    include $_SERVER["DOCUMENT_ROOT"] . '/engine/forms/workout_delete_form.php';
    ?>
    </div>

    <div class="box">
    <?php
    include $_SERVER["DOCUMENT_ROOT"] . '/generated_content/workout/summary.html';
    ?>
    </div>

</div>

</body>
</html> 
