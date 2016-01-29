use Test::More import => ['!pass'];
use strict;
use warnings;

use Dancer ':syntax';
use Plack::Test;

use File::Spec;
use lib File::Spec->catdir('t','lib');


my $confs = { '/hash' => [['Runtime']], };

my @tests =
  ( { path => '/', runtime => 0 }, { path => '/hash', runtime => 1 } );

plan tests => (2 * scalar @tests);

test_psgi(
    client => sub {
        my $cb = shift;

        foreach my $test (@tests) {
            my $req =
              HTTP::Request->new(
                GET => "http://localhost" . $test->{path} );
            my $res = $cb->($req);
            ok $res;
            if ( $test->{runtime} ) {
                ok $res->header('X-Runtime');
            }
            else {
                ok !$res->header('X-Runtime');
            }
        }
    },
    app => do {
        my $port = shift;

        use TestApp;
        Dancer::Config->load;

        set( environment           => 'production',
             apphandler            => 'PSGI',
             startup_info          => 0,
             plack_middlewares_map => $confs );

        Dancer->dance;
    },
);
