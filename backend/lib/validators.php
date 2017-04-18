<?php

function is_nonnegative_int($to_assert)
{
  if(!is_int($to_assert)) return false;
  if($to_assert < 0) return false;

  return true;
}

function is_nonnegative_number($to_assert)
{
  if(! (is_float($to_assert) || is_int($to_assert) ) ) return false;
  if($to_assert < 0) return false;

  return true;
}

function is_number($to_assert)
{
  return (is_float($to_assert) || is_int($to_assert) );
}

function is_date($date)
{
    if(!is_string($date)) return false;
    // check, if date format is valid by regex and write matches
    // into $matches
    // if( !preg_match( "/^(\\d{2})\\S(\\d{2})\\S((\\d{2}){1,2})$/", $date, $matches ) )
    if( !preg_match( "/^(\\d{4})-(\\d{2})-(\\d{2})$/", $date, $matches ) ) return false;
    // check if date actually exists
    if(! checkdate( intval($matches[2]), intval($matches[3]), intval($matches[1]) ) ) return false;

    return true;
}

// validate balances [-]dd[.d[d]]
// returns: 
// Array with the two keys "valid" and "error"
//  valid: Bool, True iff the string is valid
//  error: String, empty iff the string is valid
function validate_balance ($amount) {
    if(empty($amount))
    {
        return array(
            "valid" => False,
            "error" => 'Betrag fehlt.',
        );
    }
    if(! preg_match( "/^-?\\d+(\\.\\d{1,2})?$/", $amount ) )
    {
        return array(
            "valid" => False,
            "error" => 'Falsches Format.',
        );
    }

    return array(
        "valid" => True,
        "error" => '',
    );
}


// validate numbers d+
// returns: 
// Array with the two keys "valid" and "error"
//  valid: Bool, True iff the string is valid
//  error: String, empty iff the string is valid
function validate_number ($number) {
    if(empty($number))
    {
        return array(
            "valid" => False,
            "error" => 'Anzahl fehlt.',
        );
    }
    if( !preg_match( "/^\\d+$/", $number ) )
    {
        return array(
            "valid" => False,
            "error" => 'Falsches Format.',
        );
    }

    return array(
        "valid" => True,
        "error" => '',
    );
}

// validate non-empty fields
// returns: 
// Array with the two keys "valid" and "error"
//  valid: Bool, True iff the string is valid
//  error: String, empty iff the string is valid
function validate_nonempty ($string) {
    if(empty($string))
    {
        return array(
            "valid" => False,
            "error" => 'Name fehlt.',
        );
    }

    return array(
        "valid" => True,
        "error" => '',
    );
}

?>
