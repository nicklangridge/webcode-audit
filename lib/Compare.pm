package Compare;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;
  
  $self->plugin('config');
  
  my $r = $self->routes;
  $r->route('/')->to('main#index');
  $r->route('/audit')->to('main#audit');
}

1;
