package Compare::Main;
use Mojo::Base 'Mojolicious::Controller';
use Compare::Utils qw(extract_methods);
use Data::Dumper;

sub index {
  my $self = shift;
  my $info;
  my @valid_params = qw(a_path a_label b_path b_label plugin_dirs module method);
  my %params = map {$_ => scalar $self->param($_)} @valid_params;
    
  if ($self->req->method eq 'POST') {
    my $plugin_dirs = [split(/[\s,]+/, $params{plugin_dirs})];      
    
    my %spec = (
      plugin_dirs => $plugin_dirs,
      module      => $params{module},
      method      => $params{method},
    );
    
    $info = {
      a => {
        label   => $params{a_label},
        methods => extract_methods(%spec, path => $params{a_path}), 
      },
      b => {
        label   => $params{b_label},
        methods => extract_methods(%spec, path => $params{b_path}), 
      },
      plugin_dirs => $plugin_dirs,
    };
  
    $info->{plugin_names}->{$_} = ($_ eq '/' ? 'ensembl' : $_) foreach @$plugin_dirs;
  }
  
  $self->render(info => $info, %params);
}

sub audit {
  my $self = shift;
  my @valid_params = qw(a_codebase b_codebase plugin_dirs);
  my %params = map {$_ => scalar $self->param($_)} @valid_params;
  my $info;
  
  warn Dumper $self->config->{codebases};
  
  $self->render(
    codebases => $self->config->{codebases},
    info      => $info, 
    %params
  );
}

1;
