use Test::More import => ['!pass'];
use strict;
use warnings;

use Dancer ':syntax';
use Plack::Test;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

my $confs = [ [ [ ['Runtime'] ] ] ];

plan tests => (2 * scalar @$confs);


foreach my $c (@$confs) {
    test_psgi(
        client => sub {
            my $cb = shift;

            my $req = HTTP::Request->new( GET => "http://localhost/" );
            my $res = $cb->($req);
            ok $res;
            ok $res->header('X-Runtime');
        },
        app => do {
            my $port = shift;

            use TestApp;
            Dancer::Config->load;

            set( environment       => 'production',
                 apphandler        => 'PSGI',
                 startup_info      => 0,
                 plack_middlewares => $c->[0] );
            Dancer->dance;
        },
    );

}
