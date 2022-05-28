package SampleMojoApp::Controller::Example;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use SampleMojoApp::Util;

# This action will render a template
sub welcome ($c) {

  $c->log->info("welcome our guest, plain log message");

  $c->log->error(h2s(
        msg => 'itest_h2s_quote_on_space_found_logic',
        param => 38
    ));

  $c->log->info(h2snum(
        msg => 'test_h2s_quote_on_not_looks_like_number_logic',
        param => "0.1"
    ));

  # test Dumper
  my $result = {
      a => 'apple',
      cost => 2.8
  };
  $c->log->info('msg="dumper test at Example:" dump=%s', "\n". Dumper($result));

  # Render template "example/welcome.html.ep" with message
  $c->render(msg => 'Welcome to the Sample Mojolicious App');
}

1;
