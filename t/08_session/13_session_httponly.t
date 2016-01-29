use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer::ModuleLoader;
use Dancer;
use Dancer::Cookie;

plan skip_all => "YAML is needed for this test"
  unless Dancer::ModuleLoader->load("YAML");

plan tests => 3 * 3;

use Plack::Test;
use File::Path 'rmtree';
use Dancer::Config;

my $session_dir = path( Dancer::Config::settings->{appdir}, "sessions_$$" );
set session_dir => $session_dir;

for my $setting ("default", "on", "off") {
    test_psgi(
        client => sub {
            my $cb = shift;
            my $req =
              HTTP::Request->new(GET => "http://127.0.0.1/set_session/test_13");
            my $res = $cb->($req);
            ok $res->is_success, 'req is success';
            my $cookie = $res->header('Set-Cookie');
            ok $cookie, 'cookie is set';
            if ($setting eq "on" || $setting eq "default") {
                my ($httponly) = ($cookie =~ /HttpOnly/);
                ok $httponly, 'httponly is present in cookie';
            } else {
                my ($httponly) = ($cookie =~ /HttpOnly/);
                ok !$httponly, 'httponly is not present in cookie';
            }

    },
    app => do {
        use File::Spec;
        use lib File::Spec->catdir( 't', 'lib' );
        use TestApp;
        Dancer::Config->load;

        setting session              => 'YAML';
        if ($setting eq "on") {
            setting session_is_http_only => 1;
        } elsif ($setting eq "off") {
            setting session_is_http_only => 0;
        }
        set( environment          => 'production',
             apphandler           => 'PSGI',
             startup_info         => 0 );
        Dancer->dance();
        },
    );

}

# clean up after ourselves
rmtree($session_dir);

