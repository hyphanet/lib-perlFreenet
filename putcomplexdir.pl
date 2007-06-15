#! perl

# test insert of a freesite, this expects a dummy site in testsite/*

use Data::Dumper;
use File::Slurp;

use Freenet::Message;
use Freenet::Connection;

$node=Freenet::Connection->new({Node => 'localhost', Client=>'perl putcomplexdir', Debug=>1});
($nodehello=$node->connect) || warn "connect failed\n";

if($nodehello->message ne "NodeHello") {
  die "something went wrong, got ".$nodehello->message." instead of NodeHello\n";
}

$file0=read_file("testsite/index.html");
$file1=read_file("testsite/foo.zip", binmode=>':raw');
$file2=read_file("testsite/doc.pdf", binmode=>':raw');

$msg=Freenet::Message->new("ClientPutComplexDir",
	{
		Identifier=>"My Test Dir Insert",
		Verbosity=>1023,
		MaxRetries=>999,
		PriorityClass=>2,
		URI=>'CHK@',
		GetCHKOnly=>"true",
		DontCompress=>"false",
		ClientToken=>"My Client Token",
		Persistence=>"connection",
		Global=>"false",
		DefaultName=>"index.html",
		Files => [
							{
								Name=>"index.html",
								UploadFrom=>"direct",
								"Metadata.ContentType"=>"text/html",
								DataLength=>length($file0),
							},
							{
								Name=>"foo.zip",
								UploadFrom=>"direct",
								"Metadata.ContentType"=>"application/zip",
								DataLength=>length($file1),
							},
							{
								Name=>"doc.pdf",
								UploadFrom=>"direct",
								"Metadata.ContentType"=>"application/pdf",
								DataLength=>length($file2),
							},
						]
	}
);

$msg->{data}=$file0.$file1.$file2;

$node->sendmessage($msg);

while(1) {
  my($msg)=$node->getmessage;
  # TODO: should catch error messages as well
  last if $msg->message eq "PutSuccessful";
}

$node->disconnect || warn "disconnect failed\n";
