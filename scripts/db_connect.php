<?php
	$user = "";
	$pw = "";
	$database = "";
	$host = "";
	
	try
	{
		$db = new PDO('mysql:dbname='.$database.';host='.$host, $user, $pw);
	}
	catch(PDOException $e)
	{
		die("Exception creating database connection.");
	}
?>
