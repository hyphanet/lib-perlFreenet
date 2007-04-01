#! perl

use Data::Dumper;
use File::Slurp;

use Freenet::Message;
use Freenet::Connection;

$node=Freenet::Connection->new({Node => 'localhost', Client=>'perl putcomplexdir', Debug=>1});
($nodehello=$node->connect) || warn "connect failed\n";

if($nodehello->message ne "NodeHello") {
  warn "something went wrong, got ".$nodehello->message." instread of NodeHello\n";
}

$file0=read_file("index.html");
$file1=read_file("foo.zip",{binmode=>':raw'});
$file2=read_file("doc.pdf",{binmode=>':raw'});

$msg=Freenet::Message->new("ClientPutComplexDir",
	{
		Identifier=>"My Test Dir Insert",
		Verbosity=>1023,
		MaxRetries=>999,
		PriorityClass=>2,
		URI=>'CHK@',
		GetCHKOnly=>"false",
		DontCompress=>"false",
		ClientToken=>"My Client Token",
		Persistence=>"connection",
		Global=>"false",
		DefaultName=>"index.html",
		"Files.0.Name"=>"index.html",
		"Files.0.UploadFrom"=>"direct",
		"Files.0.Metadata.ContentType"=>"text/html",
		"Files.0.DataLength"=>length($file0),
		"Files.1.Name"=>"foo.zip",
		"Files.1.UploadFrom"=>"direct",
		"Files.1.Metadata.ContentType"=>"application/zip",
		"Files.1.DataLength"=>length($file1),
		"Files.2.Name"=>"doc.pdf",
		"Files.2.UploadFrom"=>"direct",
		"Files.2.Metadata.ContentType"=>"application/pdf",
		"Files.2.DataLength"=>length($file2),
	}
);

$msg->{data}=$file0.$file1.$file2;

$node->sendmessage($msg);

while(1) {
  my($msg)=$node->getmessage;
}
$node->disconnect || warn "disconnect failed\n";
