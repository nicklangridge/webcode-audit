package Compare::Auditor;
use Moose;
use namespace::autoclean;
use uni::perl;
use File::Find;
use List::MoreUtils qw(uniq);
use PPI;
use Data::Dumper;


has 'old_path' => (
  is => 'rw',
  isa => 'Str', 
  required => 1,
);

has 'new_path' => (
  is => 'rw',
  isa => 'Str', 
  required => 1,
);

has 'plugins' => (
  is => 'rw',
  isa => 'ArrayRef', 
  required => 1,
);

sub audit {
  my $self = shift;
  my $data;
  
  warn "Begin audit\n";
  
  foreach my $module (@{$self->modules('new')}) {
    
    warn "processing $module\n";
    
    my ($plugin_methods, $all_methods);

    # plugins
    foreach my $plugin (@{$self->plugins}) {
      my $methods = $self->module_methods($plugin, $module);
      $data->{$module}->{$plugin}->{methods} = $methods;
      $plugin_methods->{$_} = 1 foreach (keys %$methods);
    }

    # core
    my $core_methods = $self->module_methods('/', $module, [keys %$plugin_methods]);
    $all_methods->{$_} = $core_methods->{$_} foreach (keys %$plugin_methods);
    $data->{$module}->{'/'}->{methods} = $all_methods;
  }
  
  warn "End audit\n";
  
  return $data;
}

sub modules {
  my ($self, $codebase) = @_;

  unless ($self->{_cache}->{modules}->{$codebase}) {
    my @dirs = map {$self->path_for($codebase, $_)} @{$self->plugins};
    my $found;
    my $wanted = sub {
      if (/\.pm$/) {
        my $dir  = $File::Find::topdir;
        my $file = $File::Find::name;
        (my $relative_file = $file) =~ s/^$dir\///;          
        $found->{$relative_file} = 1
      }
    };
    find($wanted, @dirs);
    $self->{_cache}->{modules}->{$codebase} = [sort keys %$found];
  }

  return $self->{_cache}->{modules}->{$codebase};
}

sub module_methods {
  my ($self, $plugin, $module, $wanted) = @_;
  my $methods;
  my $ofile = $self->path_for('old', $plugin, $module);
  my $nfile = $self->path_for('new', $plugin, $module);
  my $osubs = $self->parse_subs($ofile, $wanted);
  my $nsubs = $self->parse_subs($nfile, $wanted);
  foreach my $sub (uniq(keys %$osubs, keys %$nsubs)) {
    my $otext = $osubs->{$sub};
    my $ntext = $nsubs->{$sub};
    my $state = (!$otext && $ntext) ? 'new' :
                ($otext && !$ntext) ? 'removed' :
                ($otext &&  $ntext) ? 'present' : 'na';
    ($state = $otext ne $ntext ? 'changed' : 'same') if $state eq 'present';
    $methods->{$sub} = $state;
  }
  return $methods || {};
}

sub parse_subs {
  my ($self, $file, $wanted) = @_;
  return {} unless -f $file;
  my $subs; 
  my $document = PPI::Document->new($file) or die "PPI could not open file '$file': $@";
  $document->index_locations;
  for my $sub ( @{ $document->find('PPI::Statement::Sub') || [] } ) {
    unless ($sub->forward) {
      if (!$wanted or grep {$_ eq $sub->name} @$wanted) {
        $subs->{$sub->name} = $sub->content;
      }
    }
  }
  return $subs || {};
}

sub path_for {
  my ($self, $codebase, $plugin, $module) = @_;
  my $method = "${codebase}_path";
  return ($self->$method) . "/$plugin/modules/$module";
}

__PACKAGE__->meta->make_immutable;

1;