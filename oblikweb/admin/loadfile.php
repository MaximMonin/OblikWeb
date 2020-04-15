<?php

$method = $_GET['method'];
$name = $_GET['name'];

/* Figure out the MIME type (if not specified) */
$known_mime_types=array(
 	"pdf" => "application/pdf",
 	"txt" => "text/plain",
 	"html"=> "text/html",
 	"htm" => "text/html",
	"exe" => "application/octet-stream",
	"zip" => "application/zip",
	"doc" => "application/msword",
	"xls" => "application/vnd.ms-excel",
	"ppt" => "application/vnd.ms-powerpoint",
	"gif" => "image/gif",
	"png" => "image/png",
	"jpeg"=> "image/jpg",
	"jpg" => "image/jpg",
	"php" => "text/plain"
);
 
$file_extension = strtolower(substr(strrchr($name,"."),1));
if(array_key_exists($file_extension, $known_mime_types))
{
  $mime_type=$known_mime_types[$file_extension];
} else 
{
  $mime_type="application/force-download";
};

if ( isset ( $GLOBALS["HTTP_RAW_POST_DATA"] )) {
        
        // get bytearray
        $rawfile = $GLOBALS["HTTP_RAW_POST_DATA"];
        
        // add headers for download dialog-box
        header('Content-Type: ' . $mime_type);
        header('Content-Length: '.strlen($rawfile));
        header('Content-disposition:'.$method.'; filename="'.$name.'"');
        echo $rawfile;
        
}  else echo 'An error occured.';

?>
