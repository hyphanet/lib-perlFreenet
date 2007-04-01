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
    # if we don't have header field, you can just leave them out
    # e.g. ->new("ShutDown");
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
		my $k=shift;
    return $self->{header}->{$k};
	}
}

# as_string is useful for debugging, returns the complete message ending
# with either EndMessage or Data

sub as_string
{
	my($self)=shift;
	
	my($s)=$self->message."\n";
	foreach my $k (keys(%{$self->header})) {
	  $s.=$k."=".$self->header($k)."\n";
	}
	if(defined($self->data)) {
		# ignore the data field for now
	  $s.="Data\n";
	} else {
	  $s.="EndMessage\n";
  }
	return $s;
}

1;
