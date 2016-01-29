use Dancer ':tests';
use Dancer::Test;
use Test::More;
use Dancer::ModuleLoader;
use LWP::UserAgent;
use Plack::Test;

plan skip_all => 'JSON is needed to run this test'
    unless Dancer::ModuleLoader->load('JSON');

plan tests => 4;

set serializer => 'JSON';

my $data = { foo => 'bar' };

test_psgi(
    client => sub {
        my $cb    = shift;
        my $request = HTTP::Request->new( GET => "http://127.0.0.1/" );
        my $res;

        $res = $cb->($request);
        ok( $res->is_success, 'Successful response from server' );
        like(
            $res->content,
            qr/"foo" \s \: \s "bar"/x,
            'Correct content',
        );

        # new request, no serializer
        $res = $cb->($request);
        ok( $res->is_success, 'Successful response from server' );
        like($res->content, qr/HASH\(0x.+\)/,
            'Serializer undef, response not serialised');
    },

    app => do {
        use Dancer ':tests';

        set( apphandler   => 'PSGI',
             show_errors  => 1,
             startup_info => 0 );

        get '/' => sub { $data };

        hook after => sub { set serializer => undef };

        Dancer->dance();
    },
);

