package SampleMojoApp::Plugin::AppHelpers;

use Mojo::Base 'Mojolicious::Plugin', -signatures, -async_await;
use Data::UUID::MT;
use Mojo::UserAgent;
use Mojo::Promise;
use Mojo::IOLoop;
use SampleMojoApp::Util;
use Encode;
use Crypt::PRNG qw(random_bytes);
use Crypt::Argon2 qw(argon2i_pass argon2i_verify);
use MongoDB;

has pwhash => '$argon2i$v=19$m=64,t=2,p=1$yGAFgLyh/+JofinLLt6oxQ$H+cUfKMuI0kzKr2IxvD1Lw';

has dbclient => sub {
    MongoDB::MongoClient->new(
        host => '10.1.1.4:27017',
		username => 'core',
		password => 'skylink',
        auth_mechanism => 'MONGODB-CR',
		db_name => 'hu',
    );
};

has db => sub($self) {
    state $db = $self->dbclient->get_database( 'hu' );
};

has 'helper_ua' => sub {
    warn "# @@@ has helper_ua called";
    Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);
};

sub _check_call($c,$arg) {
    warn "# @@@ _check_call is called with arg=".$arg;
}

sub register ($self, $app, $conf) {
    $self->{ug} ||= Data::UUID::MT->new( version => 4 );
    $self->{ua} = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);

    $app->helper('ah.render_with_header' => sub ($c, @args) {
        $c->res->headers->header('X-Mojo' => 'I <3 Mojolicious!');
        $c->render(@args);
    });

    $app->helper('check_call' => \&_check_call);

    $app->helper('ah.ug' => sub ($c) {
        return $self->{ug};
    });

    $app->helper('ah.getuuid' => sub ($c) {
        return unpack("H*", $self->{ug}->create);
    });

    # short name:
    $app->helper('top_get_uuid' => sub ($c) {
        return unpack("H*", $self->{ug}->create);
    });

    # get external data in async/await mode
    # the helper will always return a promise object, so use then and catch
    $app->helper('get_site_title' => async sub ($c, $url) {
        my ($tx, $err);
        eval {
            $tx = await $self->helper_ua->get_p($url)
                ->catch(sub { ($err) = @_; });
        };
        die "$err" if $err;
        my $result = $tx->result;
        if ($result->is_success) {
            my $title = $result->dom->at('title')->text;
            $c->log->debug(h2s(
                act => 'get_site_title',
                msg => 'ok, return title',
                title => $title,
            ));
            return $title;
        }
        elsif ($result->is_error) {
            $c->log->error(h2s(
                act => 'get_site_title',
                msg => 'tx failed',
                code => $result->code,
                error => $result->message
            ));
            die $result->message;
        }
        else {
            die 'unknown error condition';
        }
    });

    $app->helper('get_title_p' => sub($c,$url) {
        return $self->{ua}->get_p($url)->then(sub ($tx) {
            my $result = $tx->result;
            die $result->message if $result->is_error;
            die 'unknown error condition' unless $result->is_success;
            $result->dom->at('title') or die "no title";
            return $result->dom->at('title')->text;
        });
    });

    $app->helper('sec.verify_pw' => sub($c, $pw) {
        Mojo::IOLoop->subprocess->run_p(sub {
            return argon2i_verify($self->pwhash, encode('UTF-8',$pw));
        });
    });

    $app->helper('sec.hash_pw' => sub($c, $pw) {
        Mojo::IOLoop->subprocess->run_p(sub {
            # argon2i_pass($password, $salt, $t_cost, $m_factor, $parallelism, $tag_size)
            return argon2i_pass(encode('UTF-8',$pw), random_bytes(16), 2, '32M', 4, 16);
        });
    });

    $app->helper('db.readrow' => sub($c, $user_id) {
        Mojo::IOLoop->subprocess->run_p(sub {
            return $self->db->coll('users.lwa')->find_one({user_id => int $user_id});
        });
    });

    $app->helper('db.get_devices' => sub($c, $hub_id) {
        Mojo::IOLoop->subprocess->run_p(sub {
            $self->dbclient->reconnect;
            my @devices = $self->db->coll('hub.device')->find({hub_id => "$hub_id"})->all;
            return \@devices;
        });
    });

    # Mojo::IOLoop->recurring( 5 => sub { warn "tick..."; } );
}

1;

__DATA__
