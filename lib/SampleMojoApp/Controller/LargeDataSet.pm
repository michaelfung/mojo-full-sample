package SampleMojoApp::Controller::LargeDataSet;
use Mojo::Base 'Mojolicious::Controller', -signatures, -async_await;
use Mojo::Promise;
use SampleMojoApp::Util;
use JSON::XS;

# showcase how to return a large data set

sub large_set ( $c ) {

  # data set size in json objects
  my $size = $c->param( 'size' ) // 1_000;

  my $drain = sub {
    my $c = shift;
    return $c->finish unless $size > 0;
    my $chunk;
    for ( 1 .. 100 ) {
      $chunk .= encode_json( { row => $size--, id => uuid_hex() } ) . "\n";
    }
    my $bytes = length $chunk;
    #warn "large_set send chunk with size of: $bytes bytes";
    $c->write_chunk( $chunk, __SUB__ );
  };
  $c->$drain;
}

1;
