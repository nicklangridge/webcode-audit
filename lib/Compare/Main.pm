package Compare::Main;
use Mojo::Base 'Mojolicious::Controller';
use Compare::Auditor;

sub audit {
  my $self = shift;
  my @valid_params = qw(old_codebase new_codebase plugin_dirs);
  my %params       = map {$_ => scalar $self->param($_)} @valid_params;
  my $codebases    = $self->config->{codebases};
  my $old_path     = $codebases->{$params{old_codebase}};
  my $new_path     = $codebases->{$params{new_codebase}};
  my @plugins      = split /[\s,]+/, $params{plugin_dirs};
  my $audit;
  
  my $t = time;
  
  if ($old_path and $new_path) {

    my $auditor = Compare::Auditor->new(
      old_path => $old_path,
      new_path => $new_path,
      plugins  => \@plugins,
    );

    $audit = $auditor->audit;
  }

  $self->render(
    codebases => $codebases,
    plugins   => \@plugins,
    audit     => $audit,
    runtime   => time - $t,
    %params
  );
}

sub diff {
  my $self = shift;
  my @valid_params = qw(old_codebase new_codebase plugin_dirs module method);
  my %params       = map {$_ => scalar $self->param($_)} @valid_params;
  my $codebases    = $self->config->{codebases};
  my $old_path     = $codebases->{$params{old_codebase}};
  my $new_path     = $codebases->{$params{new_codebase}};
  my $module       = $params{module};
  my $method       = $params{method};
  my @plugins      = split /[\s,]+/, $params{plugin_dirs};
  my $methods;
    
  my $t = time;
  
  if ($old_path and $new_path and $module and $method) {   
    
    my $auditor = Compare::Auditor->new(
      old_path => $old_path,
      new_path => $new_path,
      plugins  => \@plugins,
    );

    $methods = {
      old => {
        label   => $params{old_codebase},
        path    => $old_path,
        methods => $auditor->extract_method_versions('old', $module, $method),
      },
      new => {
        label   => $params{new_codebase},
        path    => $new_path,
        methods => $auditor->extract_method_versions('new', $module, $method),
      },
    }
  }
  
  $self->render(
    codebases => $codebases,
    plugins   => ['/', @plugins],
    runtime   => time - $t,
    methods   => $methods, 
    %params
  );
}



# sub index {
#   my $self = shift;
#   my $info;
#   my @valid_params = qw(a_path a_label b_path b_label plugin_dirs module method);
#   my %params = map {$_ => scalar $self->param($_)} @valid_params;
    
#   if ($self->req->method eq 'POST') {
#     my $plugin_dirs = [split(/[\s,]+/, $params{plugin_dirs})];      
    
#     my %spec = (
#       plugin_dirs => $plugin_dirs,
#       module      => $params{module},
#       method      => $params{method},
#     );
    
#     $info = {
#       a => {
#         label   => $params{a_label},
#         methods => extract_methods(%spec, path => $params{a_path}), 
#       },
#       b => {
#         label   => $params{b_label},
#         methods => extract_methods(%spec, path => $params{b_path}), 
#       },
#       plugin_dirs => $plugin_dirs,
#     };
  
#     $info->{plugin_names}->{$_} = ($_ eq '/' ? 'ensembl' : $_) foreach @$plugin_dirs;
#   }
  
#   $self->render(info => $info, %params);
# }


1;
