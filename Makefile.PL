use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Locale::Maketext::Test',
    AUTHOR             => q{Binary.com <binary@cpan.org>},
    VERSION_FROM       => 'lib/Locale/Maketext/Test.pm',
    ABSTRACT_FROM      => 'lib/Locale/Maketext/Test.pm',
    LICENSE            => 'apache',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Moose'                             => 0,
        'Try::Tiny'                         => 0,
        'Encode'                            => 0,
        'Locale::Maketext::ManyPluralForms' => 0,
        'Test::More'                        => 0
    },
    PREREQ_PM => {
        'Moose'                             => 0,
        'Try::Tiny'                         => 0,
        'Encode'                            => 0,
        'Locale::Maketext::ManyPluralForms' => 0
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean      => {FILES => 'Local-Maketext-Test-*'},
    META_MERGE => {
        requires  => {perl => 5.006},
        resources => {
            homepage   => 'https://github.com/binary-com/perl-Locale-Maketext-Test',
            bugtracker => 'https://github.com/binary-com/perl-Locale-Maketext-Test/issues',
            repository => 'https://github.com/binary-com/perl-Locale-Maketext-Test',
            license    => 'http://dev.perl.org/licenses/',
        },
        x_contributors => ['Raunak Kathuria <raunakkathuria at gmail.com>'],
    },
);
