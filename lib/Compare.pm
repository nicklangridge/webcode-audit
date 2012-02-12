package Compare;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;
  
  $self->plugin('config');
  
  my $r = $self->routes;
  #$r->route('/')->to('main#audit');
  $r->route('/audit')->to('main#audit');
  $r->route('/diff')->to('main#diff');
}

1;
