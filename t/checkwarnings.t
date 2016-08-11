use Test::More;
use Test::NoWarnings;
use Locale::Maketext::Test;

plan tests => 3;

my $handler = Locale::Maketext::Test->new(
    directory => 't/locales',
    languages => ['pt'],
    debug     => 1
);

my $result = $handler->testlocales();

is $result->{status}, 0, 'Status is 1 as auto flag has been set';
is scalar @{$result->{warnings}->{pt}}, 2, 'Got warnings as parameters are not properly used';

