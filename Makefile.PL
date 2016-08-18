use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Locale::Maketext::Test',
    AUTHOR             => q{Binary.com <binary@cpan.org>},
    VERSION_FROM       => 'lib/Locale/Maketext/Test.pm',
    ABSTRACT           => 'test validity of .po translation files',
    LICENSE            => 'apache',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Moose'                             => 0,
        'Try::Tiny'                         => 0,
        'File::Spec'                        => 0,
        'File::Basename'                    => 0,
        'namespace::autoclean'              => 0,
        'Test::MockModule'                  => 0,
        'Test::More'                        => 0,
        'Test::Exception'                   => 0,
        'Test::NoWarnings'                  => 0,
        'Locale::Maketext::ManyPluralForms' => 0
    },
    PREREQ_PM => {
        'Moose'                             => 0,
        'Try::Tiny'                         => 0,
        'File::Spec'                        => 0,
        'namespace::autoclean'              => 0,
        'Test::MockModule'                  => 0,
        'Locale::Maketext::ManyPluralForms' => 0
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean      => {FILES => 'Local-Maketext-Test-*'},
    META_MERGE => {
        requires  => {perl => 5.014},
        resources => {
            homepage   => 'https://github.com/binary-com/perl-Locale-Maketext-Test',
            bugtracker => 'https://github.com/binary-com/perl-Locale-Maketext-Test/issues',
            repository => 'https://github.com/binary-com/perl-Locale-Maketext-Test',
            license    => 'http://dev.perl.org/licenses/',
        },
        x_contributors => ['Raunak Kathuria <raunakkathuria at gmail.com>'],
    },
);
