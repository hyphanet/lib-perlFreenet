package Freenet::Message;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}

sub initialize
{
    my $self = shift;

    $self->{data}=undef;
    $self->{message}=shift;
    # if there are no header fields, you can just leave them out
    # e.g. ->new("Shutdown");
    $self->{header}=shift || {};
}

# TODO: how can these be assigned to?
sub data
{
  return shift->{data};
}

# TODO: should this be called "name" or "messagename"?
sub message
{
	return shift->{message};
}

# get header hash ref or one header

sub header
{
	my($self)=shift;
	if(int(@_)==0) {
    return $self->{header};
	} else {
		my @keys;
		if(int(@_)>1) {
			@keys=@_;
		} else {
			my $key=shift;
			if($key=~/\./) {
				if(defined($self->{header}->{$key})) {
					return $self->{header}->{$key}
				}
			}
			@keys=split(/\./,$key);
		}
		my $ref=$self->{header};
		foreach my $k (@keys) {
			$ref=$ref->{$k};
			if(!defined($ref)) {
				return undef;
			}
		}
    return $ref;
	}
}

# as_string is useful for debugging, returns the complete message ending
# with either EndMessage or Data
# TODO: this duplicates code from Freenet::Connection

sub as_string
{
	my($self)=shift;
	
	my($s)=$self->message."\n";
	foreach my $k (keys(%{$self->header})) {
	  $s.=$self->string_msghash($k, $self->header->{$k});;
	}
	if(defined($self->data)) {
		# ignore the data field for now
	  $s.="Data\n";
	} else {
	  $s.="EndMessage\n";
  }
	return $s;
}

sub string_msghash
{
  my($self)=shift;
  my($key)=shift;
  my($value)=shift;

	my($res)="";

  if(ref($value)) {
  	if(ref($value) eq "ARRAY") {
  		for(my $i=0;$i<int(@$value);$i++) {
  			$res.=$self->string_msghash("$key.$i",$value->[$i]);
  		}
  	}
  	elsif(ref($value) eq "HASH") {
  		foreach my $k (keys(%$value)) {
  			$res.=$self->string_msghash("$key.$k",$value->{$k});
  		}
  	}
  	else {
  		warn "unsupported value type ".ref($value)."\n";
  	}
  } else {
  	$res.="$key=$value\n";
  }
  return $res;
}

1;
