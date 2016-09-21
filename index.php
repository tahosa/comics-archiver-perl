<?php 
	$template = file_get_contents("template1.html");
	$homeTxt = file_get_contents("home.txt");
	
	$homeTxt = preg_replace("/,,,content,,,/i", $homeTxt, $template);
	$homeTxt = preg_replace("/,,,TITLE,,,/i", "The Webcomic Archive", $homeTxt);
	
	echo $homeTxt;
?>