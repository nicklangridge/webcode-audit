package Compare::Utils;
use strict;
use warnings;
use PPI;
use Data::Dumper;

use base 'Exporter';
our @EXPORT = qw(extract_methods);

sub extract_methods {
  my (%args)      = @_;
  my $path        = $args{path};
  my @plugin_dirs = @{$args{plugin_dirs}};
  my $module      = $args{module};
  my $method      = $args{method};
  my %subs;
  
  foreach my $plugin_dir (@plugin_dirs) {
    my $file = "$path/$plugin_dir/$module";
    $subs{$plugin_dir} = -f $file ? _extract_method($file, $method) : undef;
  }  
  return \%subs;
}

sub _extract_method {
  my ($file, $method) = @_;
  my $content;
  my $document = PPI::Document->new($file) or die "PPI could not open file '$file': $@";
  $document->index_locations;
  for my $sub ( @{ $document->find('PPI::Statement::Sub') || [] } ) {
    unless ( $sub->forward ) {
      if ($sub->name eq $method) {
        $content = $sub->content,
        last;
      }
    }
  }
  return $content;
}

