#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Locale::Maketext::Test' ) || print "Bail out!\n";
}

diag( "Testing Locale::Maketext::Test $Locale::Maketext::Test::VERSION, Perl $], $^X" );
