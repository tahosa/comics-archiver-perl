<?php
	
	$num = $_REQUEST['num'];
	
	include("../scripts/db_connect.php");

	$fileQuery = "SELECT number, filename, altText FROM files WHERE cName=? ORDER BY number";
	$allSelect = "SELECT cName, folder, number FROM comics ORDER BY cName";
	
	$template = file_get_contents("../template1.html");
	$content = "";
	
	if($num == NULL || $num == 0)
		$num = 1;
		
	$cnR = $db->prepare($allSelect);
	$cnR->execute();
	
	while($row = $cnR->fetch(PDO::FETCH_ASSOC))
	{
		$fileR = $db->prepare($fileQuery);
		$fileR->bindParam(1, $row["cName"]);
		$fileR->execute();
		
		$content .= "<h2>Latest ".$row["cName"]."</h2>\n";
		$comics = $fileR->fetchAll(PDO::FETCH_ASSOC);
		
		for($i = $num; $i > 0; $i--)
		{
			$content .= $comics[count($comics)-$i]["filename"]."<br/>\n";
			$content .= "<img src='" . $row["folder"] . "/" . $comics[count($comics)-$i]["filename"] . "' title='" . $comics[count($comics)-$i]["altText"] . "' /><br/><br/>\n";
		}
	}
	
	$content = preg_replace("/,,,content,,,/i", $content, $template);
	$content = preg_replace("/,,,title,,,/i", "Latest Comics", $content);
	
	echo $content;

?>