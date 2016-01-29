use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer::Plugin::Ajax;
# GH #671

use HTTP::Request;
use Plack::Builder;
use Plack::Test;

plan tests => 6;

my $js_content = q[<script type="text/javascript">
    var xhr = new XMLHttpRequest();
    xhr.open( 'POST', '/foo' );
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    xhr.send();
    </script>
];

test_psgi(
    client => sub {
        my $cb = shift;
        my $url  = "http://127.0.0.1/";

        my $req = HTTP::Request->new(GET => $url);

        ok my $res = $cb->($req), 'Got GET result';
        ok $res->is_success, 'Successful';
        is $res->content, $js_content, 'Correct JS content';

        $req = HTTP::Request->new( POST => "${url}foo" );
        $req->header( 'X-Requested-With' => 'XMLHttpRequest' );

        ok( $res = $cb->($req), 'Got POST result' );
        ok( $res->is_success, 'Successful' );
        is( $res->content, 'bar', 'Correct content' );
    },

    app => do {
        my $handler = sub {
            use Dancer;

            set apphandler => 'PSGI', startup_info => 0;

            get  '/'    => sub {$js_content};
            ajax '/foo' => sub {'bar'};

            my $env     = shift;
            my $request = Dancer::Request->new( env => $env );
            Dancer->dance($request);
        };

        my $app = builder {
            mount "/" => $handler;
        };
    },
);

