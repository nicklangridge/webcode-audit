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

  if ($old_path and $new_path) {

    my $auditor = Compare::Auditor->new(
      old_path => $old_path,
      new_path => $new_path,
      plugins  => \@plugins,
    );

    $audit = $auditor->audit;
  }

  my $module_key = {
    new     => 'new',
    removed => 'removed',
    changed => 'changed',
    same    => '==',
    na      => '',
  };

  $self->render(
    codebases  => $codebases,
    plugins    => \@plugins,
    audit      => $audit,
    module_key => $module_key,
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
