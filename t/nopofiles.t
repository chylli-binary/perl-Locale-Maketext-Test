use Test::More;
use Test::NoWarnings;
use Test::Exception;
use Locale::Maketext::Test;

plan tests => 2;

my $handler = Locale::Maketext::Test->new(
    directory => 't/locales',
    languages => ['ID']);

throws_ok {
    $handler->testlocales()
}
qr/Cannot open/, 'No file found error';
