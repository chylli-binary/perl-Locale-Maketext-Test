use Test::More;
use Test::NoWarnings;
use Locale::Maketext::Test;

plan tests => 3;

my $handler = Locale::Maketext::Test->new(
    directory => 't/locales',
    languages => ['pt'],
    auto      => 1
);

my $result = $handler->testlocales();

is $result->{status}, 1, 'Status is 1 as auto flag has been set';
is scalar keys %{$result->{errors}}, 0, 'No error as auto flag is set';

