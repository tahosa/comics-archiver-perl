<?php

	$comic = $_REQUEST['comic'];
	$num = $_REQUEST['num'];
	$latest = $_REQUEST['latest'];
	$start = $_REQUEST['start'];
	
	include("../scripts/db_connect.php");
	
	$fileQuery = "SELECT number, filename, altText FROM files WHERE cName=? ORDER BY number";
	$folderQuery = "SELECT cName FROM comics WHERE folder=?";
	
	$fq = $db->prepare($folderQuery);
	$fq->bindParam(1, $comic, PDO::PARAM_STR, 100);
	$fq->execute();
	
	$cnR = $fq->fetch(PDO::FETCH_ASSOC);
	if(!$cnR)
	{
		die("Error processing query.\n");
	}
	$cName = $cnR["cName"];

	if(!$start)
		$start = 0;	
		
	if(!$num)
		$num == 15;
	
	
	$template = file_get_contents("../template1.html");
	$content = "";
	
	if(file_exists($comic))
	{	
		$cq = $db->prepare($fileQuery);
		$cq->execute(array($cName));
		
		$allComics = $cq->fetchAll(PDO::FETCH_ASSOC);
		$comics = array();
		
		for($i = $start; $i < $num; $i++)
		{
			$comics[] = $allComics[$i];
		}
		
		function printNav($comic, $allComics, $latest, $num, $start)
		{
			$c = "";
			$c .= "<div align='center'>";
			if($latest)
			{
				if($num != 0)
				{
					$c .= "<a href='archive.php?comic=".$comic."&start=0&num=".$num."'><img src='/images/nav_01.png' title='First' /></a>";
					if(count($allComics) - ($num * 2)  > 0)
						$c .= "<a href='archive.php?comic=".$comic."&start=" . (count($allComics) - ($num * 2)) . "&num=".$num."'><img src='/images/nav_02.png' title='Previous' /></a>";
					else
						$c .= "<a href='archive.php?comic=".$comic."&start=0&num=".$num."'><img src='/images/nav_02.png' title='Previous' /></a>";
				}
				else
				{
					$c .= "<a href='archive.php?comic=".$comic."&start=0&num=15'><img src='/images/nav_01.png' title='First' /></a>";
					if(count($allComics) > 16)
						$c .= "<a href='archive.php?comic=".$comic."&start=" . (count($allComics) - 16) . "&num=15'><img src='/images/nav_02.png' title='Previous' /></a>";
					else
						$c .= "<a href='archive.php?comic=".$comic."&start=0&num=15'><img src='/images/nav_02.png' title='Previous' /></a>";
				}
			}
			else
			{
				if($start != 0)
				{
					$c .= "<a href='archive.php?comic=".$comic."&start=0&num=".$num."'><img src='/images/nav_01.png' title='First' /></a>";
					if($start - $num > 0)
						$c .= "<a href='archive.php?comic=".$comic."&start=" . ($start - $num) . "&num=".$num."'><img src='/images/nav_02.png' title='Previous' /></a>";
					else
						$c .= "<a href='archive.php?comic=".$comic."&start=0&num=".$num."'><img src='/images/nav_02.png' title='Previous' /></a>";
				}
				
				if($num + $start < count($allComics))
				{
					$c .= "<a href='archive.php?comic=".$comic."&start=". ($num + $start) ."&num=".$num."'><img src='/images/nav_03.png' title='Next' /></a>";
					$c .= "<a href='archive.php?comic=".$comic."&latest=1&num=".$num."'><img src='/images/nav_04.png' title='Last' /></a>";
				}
				else
				{
					$c .= "<a href='archive.php?comic=".$comic."&start=". (count($allComics) - $num) ."&num=".$num."'><img src='/images/nav_03.png' title='Next' /></a>";
					$c .= "<a href='archive.php?comic=".$comic."&latest=1&num=".$num."'><img src='/images/nav_04.png' title='Last' /></a>";
				}
				
			}
			
			$c .= "<br /><a href='javascript:setSave(\"".$comic."\")'>Set Save Point</a> | <a href='javascript:restoreFromCookie(\"".$comic."\")'>Restore From Save</a><br /><br />";
			$c .= "</div>";
			
			return $c;
		}
		
		function printComic($comics, $comic, $index)
		{
			$c2 = "";
			#$c2 .= $comics[$index]["filename"]."<br />";
			$c2 .= "<p><img src='".$comic."/".$comics[$index]["filename"]."' title='".$comic."/".$comics[$index]["filename"]."' /></p>";
			
			return $c2;
		}
		
		$content .= printNav($comic, $allComics, $latest, $num, $start);
		$content .= "<div class=\"center_margin\">";
		if($latest)
		{	
			$numComics = count($allComics);
			
			for($i = $num; $i > 0;  $i--)
			{
				$content .= printComic($allComics, $comic, $numComics - $i);
			}
		}
		else
		{
			for($i = $start; $i < ($start + $num); $i++)
			{
				if($i >= count($allComics))
				{
					break;
				}
				$content .= printComic($allComics, $comic, $i);	
			}
		}
		$content .= "</div>";
		$content .= printNav($comic, $allComics, $latest, $num, $start);
	}
	else
	{
		$content .= "<h2>Not Found</h2><p>The requested comic: ". $comic ." was not found.</p>";
	}

	$content = preg_replace("/,,,content,,,/i", $content, $template);
	$content = preg_replace("/,,,title,,,/i", $cName, $content);
	
	echo $content;

?>
