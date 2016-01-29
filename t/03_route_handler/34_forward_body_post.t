use strict;
use warnings;
use Test::More import => ['!pass'];

use Carp;
$Carp::Verbose = 1;

use Dancer;
use Plack::Test;
use HTTP::Request::Common;

plan tests => 2;

test_psgi(
  client => sub {
      my $cb = shift;
      my $url_base  = "http://127.0.0.1";
      my $res = $cb->(POST $url_base . "/foo", { data => 'foo'});
      is($res->decoded_content, "data:foo");

      $res = $cb->(POST $url_base . "/foz", { data => 'foo'});
      is($res->decoded_content, "data:foo");
  },
  app => do {
      Dancer::Config->load;
      post '/foo' => sub {
          forward '/bar';
          fail "This line should not be executed - forward should have aborted the route execution";
      };
      post '/bar' => sub { join(":",params) };

      post '/foz' => sub { forward '/baz';  };
      post '/baz' => sub { join(":",params('body')) };
      set startup_info => 0, apphander => 'PSGI', show_errors  => 1;
      Dancer->dance();
  },
                   );

