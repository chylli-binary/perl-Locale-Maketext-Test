use Test::More;
use Test::NoWarnings;
use Locale::Maketext::Test;

plan tests => 5;

my $handler = Locale::Maketext::Test->new(
    directory => 't/locales',
    languages => ['id', 'ru']);
my $result = $handler->testlocales();

is $result->{status}, 0, 'locale is correct';
is scalar(keys %{$result->{errors}}), 1, 'no errors found';

is @{$result->{errors}->{ru}}[0], '(line=26): %plural() requires 3 parameters for this language (provided: 2)', 'correct error message';

is scalar(keys %{$result->{warnings}}), 0, 'no warnings found';

1;
