#! perl

use Data::Dumper;
use File::Slurp;

use Freenet::Message;
use Freenet::Connection;

$node=Freenet::Connection->new({Node => 'localhost', Client=>'perl testclient', Debug=>1});
($nodehello=$node->connect) || warn "connect failed\n";

if($nodehello->message ne "NodeHello") {
  warn "something went wrong, got ".$nodehello->message." instead of NodeHello\n";
}

# get uptime
$node->sendmessage("GetNode", {WithVolatile => 'true'});
$nodedata=$node->getmessage;
$uptime=$nodedata->header("volatile.uptimeSeconds")/3600.0;
print "uptime $uptime hours\n";

# get a list of peer node names

$node->sendmessage("ListPeers",
	{
		WithVolatile => 'true',
		WithMetadata => 'true',
	}
);

while(1) {
	my($msg)=$node->getmessage;
  if($msg->message eq "Peer") {
  	$myName=$msg->header(myName);
  	$status=$msg->header("volatile.status");
  	print "$myName $status\n";
  }
	last if $msg->message eq "EndListPeers";
};

$node->sendmessage("ClientGet",
	{
	  IgnoreDS=>"false",
	  DSOnly=>"false",
	  URI=>'USK@Aegl9hc-9O2-VMpXBYuxwuj9JAoMDdXHlNjGst1hLD8,xJTwS8hLh5Uv-20UbH9Mp64nnfqjbGkTDaUlo4EPr9M,AQACAAE/fn_rrd/2/activelink.png',
	  Identifier=>"Request Number One",
	  Verbosity=>0,
	  ReturnType=>"direct",
	  MaxSize=>1000000,
	  MaxTempSize=>1000000,
	  MaxRetries=>100,
	  PriorityClass=>1,
	  Persistence=>"connection",
	  ClientToken=>"hello",
	  Global=>"false",
	}
);

my($msg)=$node->getmessage;
print $msg->as_string;

if($msg->message ne "DataFound") {
	die "didn't get the expected message (got ".$msg->message.")\n";
}

# from the wiki documentation I thought you have to do GetRequestStatus after
# DataFound, but apparently the file is returned directly afterwards

#$node->sendmessage(Freenet::Message->new("GetRequestStatus",
#{
#  Identifier=>"Request Number One",
#  Global=>"true",
#  OnlyData=>"false",
#}
#));

$msg=$node->getmessage;
print $msg->as_string;

print "retrieved file size ".length($msg->data),"\n";

write_file("test.png", {binmode => ':raw' }, $msg->data);

$node->sendmessage("GenerateSSK", {Identifier=>"My Identifier Blah Blah"});
print $node->getmessage->as_string;

# shut down node (you probably dont want to do this is a test script)

#$node->sendmessage("Shutdown");
#print $node->getmessage->as_string;

# get CHK of a known file

# have to create the message beforehand since we have to add data element

$msg=Freenet::Message->new("ClientPut",
	{

		URI=>"CHK@",
		"Metadata.ContentType"=>"text/pdf",
		Identifier=>"My Test File",
		Verbosity=>"0",
		MaxRetries=>"10",
		PriorityClass=>"1",
		GetCHKOnly=>"true",
		Global=>"false",
		DontCompress=>"true",
		ClientToken=>"Hello!!!",
		UploadFrom=>"direct",
		TargetFilename=>"document.pdf",
	}
);

$data=read_file("c:/document.pdf",{binmode => ':raw'});

$msg->{data}=$data;
$msg->{header}->{DataLength}=length($data);

$node->sendmessage($msg);

my($msg)=$node->getmessage;
print $msg->as_string;

$node->disconnect || warn "disconnect failed\n";

