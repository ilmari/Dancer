use Test::More import => ['!pass'];
use strict;
use warnings;

use Plack::Test;
use HTTP::Request::Common;

my $app = Dancer::Handler->psgi_app;

plan tests => 3;

test_psgi(
    client => sub {
        my $cb = shift;

        my $res = $cb->(GET "http://127.0.0.1/env");
        like $res->content, qr/psgi\.version/,
            'content looks good for /env';

        $res = $cb->(GET "http://127.0.0.1/name/bar");
        like $res->content, qr/Your name: bar/,
            'content looks good for /name/bar';

        $res = $cb->(GET "http://127.0.0.1/name/baz");
        like $res->content, qr/Your name: baz/,
            'content looks good for /name/baz';
    },
    app => do {
        use File::Spec;
        use lib File::Spec->catdir( 't', 'lib' );
        use TestApp;
        use Dancer;
        set apphandler  => 'PSGI', environment => 'production';
        Dancer::Config->load;

        $app;
    },
);
