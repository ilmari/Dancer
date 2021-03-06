use Test::More import => ['!pass'];
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::ModuleLoader;
use HTTP::Tiny;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
plan skip_all => "Test::TCP is needed for this test"
  unless Dancer::ModuleLoader->load("Test::TCP" => "1.30");
plan skip_all => "Plack is needed to run this test"
  unless Dancer::ModuleLoader->load('Plack::Request');

Dancer::ModuleLoader->load('Plack::Loader');

my $confs = [ [ [ ['Runtime'] ] ] ];

plan tests => (2 * scalar @$confs);


foreach my $c (@$confs) {
    Test::TCP::test_tcp(
        client => sub {
            my $port = shift;
            my $ua   = HTTP::Tiny->new;

            my $res = $ua->get("http://127.0.0.10:$port/");
            ok $res;
            ok $res->{headers}{'x-runtime'};
        },
        server => sub {
            my $port = shift;

            use TestApp;
            Dancer::Config->load;

            set( environment       => 'production',
                 apphandler        => 'PSGI',
                 port              => $port,
                 server            => '127.0.0.10',
                 startup_info      => 0,
                 plack_middlewares => $c->[0] );
            my $app = Dancer::Handler->get_handler()->dance;
            Plack::Loader->auto( port => $port, server => '127.0.0.10' )->run($app);
        },
    );

}
