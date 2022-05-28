# data validations
package SampleMojoApp::Plugin::DV;

use Mojo::Base 'Mojolicious::Plugin', -signatures, -async_await;
use Data::UUID::MT;
use Mojo::UserAgent;
use Mojo::Promise;
use Mojo::IOLoop;
use SampleMojoApp::Constants;
use SampleMojoApp::Util;
use Data::Validate::Email qw(is_email);

sub register ( $self, $app, $conf ) {

  # signature: sub ($v, $name, $value, @args) {...};
  $app->validator->add_check(
    is_email => sub { is_email( $_[2] ) ? undef : "e:$_[1]"; } );

  $app->helper(
    'dv_map' => sub ($c) {
      return state $dv_map = {
        email => sub ($v, $required = 1) {  # special case: can be optional for some endpoints
          $required ? $v->required( 'email', 'trim' ) : $v->optional( 'email', 'trim' );
          $v->is_email;
        },
        username => sub ($v) {
          $v->required( 'username', 'trim' )->in(qw/mike admin root/);
        },
        password => sub ($v) {
          $v->required( 'password', 'trim' )->like(qr/^[[:alnum:]]+$/)
            ->size( 8, 50 );
        }
      };
    }
  );

}

1;

