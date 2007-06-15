package Freenet::Connection;

use Freenet::Message;
use IO::Socket::INET;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

# we expect a hash with options, right now we only use Node
# and Client
#
# you can use a string with the node hostname
# or nothing at all
# Node defaults to hostname:9481
# or to localhost:9481 if nothing is given.
# Client name defaults to perlfn, but please choose a sensible name
# since you can only connect with each client name once

sub initialize
{
  my $self = shift;
  my $options = shift;

	my $node;
	my $socket;
	my $clientname;
	my $debug=0;

	if(defined($options)) {
		if(ref($options)) {
			$node=$options->{Node} || "localhost";
			$clientname=$options->{Client};
			$debug=$options->{Debug} || 0;
		} else {
			# assume it's a string otherwise
			$node=$options;
		}
	}
	
	$node||="localhost";
	$clientname||="perlfn";

	# TODO: does this work with IPv6?
	if($node !~ /:\d+$/) {
	  $node.=":9481";
	}

  $self->{node}=$node;
  $self->{clientname}=$clientname;
  $self->{debug}=$debug;
  $self->{socket}=undef;
}

sub debug
{
  return shift->{debug};
}

sub connect
{
	my $self=shift;

	# connect to the node
	$socket=IO::Socket::INET->new(PeerAddr => $self->{node});

	if(!$socket) {
		# failed for some reason TODO: should wrap this is a proper error?
		return undef;
	}

  $self->debug && print "connected to ".$self->{node}."\n";

  $self->{socket}=$socket;

  # now send a ClientHello
	$msg=Freenet::Message->new("ClientHello", 
		{
			ExpectedVersion => "2.0",
		  Name => $self->{clientname},
		}
	);

	if(!($self->sendmessage($msg))) {
		return undef;
	}
	$response=$self->getmessage();

  # TODO: keep node's features somewhere so we can use it later

  return $response;
}

sub getmessage
{
  my $self=shift;

  my $socket=$self->{socket};

  my $message;
  my $headers;
  my $data;

	$_=<$socket>;
	chomp;
  $self->debug && print "<$_\n";

  $message=$_;

  while(1) {
    $_=<$socket>;
    if($_ eq "") {
      warn "read empty message from socket, probably the socket was closed by the node\n";
      return undef;
    }
    chomp;
    $self->debug && print "<$_\n";
    last if /^EndMessage$/;
    last if /^Data$/;
    my($k,$v)=split(/=/,$_,2);
    # handle keyword.keyword
    if($k=~/^([^.]+)\.(.+)$/) {
    	my($ref)=\%{$headers->{$1}};
    	my($subkey)=$2;
    	while($subkey=~/^([^.]+)\.(.+)$/) {
    		$ref=\%{$ref->{$1}};
    		$subkey=$2;
    	}
    	$ref->{$subkey}=$v;
    } else {
    	$headers->{$k}=$v;
    }
  }

  if(/^Data$/) {
    # handle data after message headers
    my($dl)=$headers->{DataLength};
    if(!defined($dl)) {
      warn "warning: Message ends with Data line, but no DataLength. We will probably break afterwards\n";
    } else {
   	  $self->debug && print "<data follows\n";
    	read($socket,$data,$dl);
   	  $self->debug && print "<read data\n";
    }
  }

  my($res)=Freenet::Message->new($message, $headers);
  if(defined($data)) {
    $res->{data}=$data;
  }

  return $res;
}

sub sendmessage
{
	my($self)=shift;
  my($msg)=shift;
  if(!ref($msg)) {
    # assume the parameters are the same as for Message->new
    $msg=Freenet::Message->new($msg,shift);
  }
  my $sock=$self->{socket};

  if(!ref($msg) eq "Freenet::Message") {
    warn "wrong argument type\n";
  }

  print $sock $msg->message,"\n";
  $self->debug && print ">".$msg->message."\n";

  foreach my $k (keys(%{$msg->header})) {
  	my($h)=$msg->header($k);
   	$self->print_msghash($k, $h);
  }

  print $sock "EndMessage\n";
  $self->debug && print ">EndMessage\n";

  if(defined($msg->data)) {
  	$self->debug && print ">data follows\n";
    print $sock $msg->data;
  	$self->debug && print ">wrote data\n";
  }

  return 1;
}

sub print_msghash
{
  my($self)=shift;
  my($key)=shift;
  my($value)=shift;
  my($sock)=$self->{socket};

  if(ref($value)) {
  	if(ref($value) eq "ARRAY") {
  		for(my $i=0;$i<int(@$value);$i++) {
  			$self->print_msghash("$key.$i",$value->[$i]);
  		}
  	}
  	elsif(ref($value) eq "HASH") {
  		foreach my $k (keys(%$value)) {
  			$self->print_msghash("$key.$k",$value->{$k});
  		}
  	}
  	else {
  		warn "unsupported value type ".ref($value)."\n";
  	}
  } else {
  	print $sock "$key=$value\n";
  	$self->debug && print ">$key=$value\n";
  }
}

sub disconnect
{
  my $self=shift;
  my $ret;

  $ret=close($self->{socket});
  $self->{socket}=undef;

  $self->debug && print "client disconnected\n";

  return $ret;
}

1;
