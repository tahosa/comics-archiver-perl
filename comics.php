<?php
	function printLinks($cname)
	{
		$text = "";
		
		$text .= "<a href='Comics/archive.php?comic=".$cname."&num=15&start=0'>First</a> - ";
		$text .= "<a href='Comics/archive.php?comic=".$cname."&num=1&latest=1'>Latest</a> - ";
		$text .= "<a href='Comics/archive.php?comic=".$cname."&num=5&latest=1'>Latest 5</a><br />";
		return $text;
	}
	
	include("scripts/db_connect.php");
	$comicQuery = "SELECT cName, folder, number, description, finished, baseURL FROM comics ORDER BY cName";
	
	$template = file_get_contents("template1.html");
	$content = "";
	
	$cnR = $db->prepare($comicQuery);
	$cnR->execute();
	
	while($row = $cnR->fetch(PDO::FETCH_ASSOC))
	{
		$content .= "<h2>".$row["cName"]." - ".$row["number"]." Comics</h2>\n";
		$content .= "<a href='".$row["baseURL"]."'>Comic Home</a><br/>";
		$content .= printLinks($row["folder"]);
		$content .= "<p>\n".$row["description"]."\n</p>\n";
		if($row["finished"]) $content .= "<p>This comic is completed and no longer updating.</p>";
	}
	
	$content = preg_replace("/,,,content,,,/i", $content, $template);
	$content = preg_replace("/,,,title,,,/i", "Comic List", $content);
	
	echo $content;
?>