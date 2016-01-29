use Test::More import => ['!pass'];
use strict;
use warnings;

use Plack::Test;
use HTTP::Request::Common;
use Dancer ':syntax';
use Dancer::ModuleLoader;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

plan tests => 2;
test_psgi(
    client => sub {
        my $cb = shift;
        my $res = $cb->(POST "http://127.0.0.1/params/route?a=1&var=query",
                            {var => 'post', b => 2});

        ok $res->is_success, 'req is success';
        my $content = $res->content;
        my $VAR1;
        eval ("$content");

        my $expected = {
                params => {
                    a => 1, b => 2,
                    var => 'post',
                },
                body => {
                    var => 'post',
                    b => 2
                },
                query => {
                    a => 1,
                    var => 'query'
                },
                route => {
                    var => 'route'
                }
        };
        is_deeply $VAR1, $expected, "parsed params are OK";
    },
    app => do {
        my $port = shift;

        use TestApp;
        Dancer::Config->load;

        set ( environment  => 'production',
              apphandler   => 'PSGI',
              startup_info => 0);
        Dancer->dance();
    },
);
