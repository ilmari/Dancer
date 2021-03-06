use Test::More import => ['!pass'];
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::ModuleLoader;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

plan skip_all => "skip test with Test::TCP in win32" if ($^O eq 'MSWin32' or $^O eq 'cygwin');
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP" => "1.30");

use HTTP::Tiny;

plan tests => 2;

my $host = '127.0.0.10';

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = HTTP::Tiny->new;
        my $res = $ua->post_form("http://$host:$port/params/route?a=1&var=query",
                            {var => 'post', b => 2});

        ok $res->{success}, 'req is success';
        my $content = $res->{content};
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
    server => sub {
        my $port = shift;

        use TestApp;
        Dancer::Config->load;

        set ( environment  => 'production',
              port         => $port,
              server       => $host,
              startup_info => 0);
        Dancer->dance();
    },
    host => $host,
);
