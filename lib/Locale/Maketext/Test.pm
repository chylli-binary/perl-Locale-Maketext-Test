package Locale::Maketext::Test;

use 5.006;
use strict;
use warnings;

use Try::Tiny;
use Encode;
use Locale::Maketext::ManyPluralForms;

=head1 NAME

Locale::Maketext::Test - The great new Locale::Maketext::Test!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This reads all message ids from the specified PO files and tries to
translate them into the destination language. PO files can be specified either
as file name (extension .po) or by providing the language. In the latter case
the PO file is found in the directory given by the directory option.

    use Locale::Maketext::Test;

    my $foo = Locale::Maketext::Test->new({directory => '/tmp/locales'});

    ### optional parameters
    # languages => ['en', 'de'] - to test specific languages in directory, else it will pick all po files in directory
    # debug     => 1 - if you want to check warnings add debug flag else it will output errors only

TYPES OF ERRORS FOUND

* unknown %func() calls
  Translations can contain function calls in the form of %func(parameters).
  These functions must be defined in our code. Sometimes translators try to
  translate the function name which then calls an undefined function.

* incorrect number of %plural() parameters
  Different languages have different numbers of plural forms. Some, like Malay,
  don't have any plural forms. Some, like English or French, have just 2 forms,
  singular and one plural. Others like Arabic or Russian have more forms.
  Whenever a translator uses the %plural() function, he must specify the correct
  number of plural forms as parameters.

* incorrect usage of %d in %plural() parameters
  In some languages, like English or German, singular is applicable only to the
  quantity of 1. That means the German translator could come up for instance
  with the following valid %plural call:

    %plural(%5,ein Stein,%d Steine)

  In other languages, like French or Russian, this would be an error. French
  uses singular also for 0 quantities. So, if the French translator calls:

    %plural(%5,une porte,%d portes)

  and in the actual call the quantity of 0 is passed the output is still
  "une porte". In Russian the problem is even more critical because singular
  is used for instance also for the quantity of 121.

  Thus, this test checks if a) the target language is similar to English in
  having only 2 plural forms, singular and one plural, and in applying
  singular only to the quantity of 1. If both of these conditions are met
  %plural calls like the above are allowed. Otherwise, if at least one of
  the parameters passed to %plural contains a %d, all of the parameters must
  contain the %d as well.

  That means the following 2 %plural calls are allowed in Russian:

    %plural(%3,%d книга,%d книги,%d книг)
    %3 %plural(%3,книга,книги,книг)

  while this is forbidden:

    %plural(%3,одна книга,%d книги,%d книг)

=head1 SUBROUTINES/METHODS

=head2 debug

set this if you need to check warnings along with errors

=cut

use Moose;
use namespace::autoclean;

has debug => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

=head2 directory

directory where locales files are located

=cut

has directory => (
    is       => 'ro',
    isa      => 'str',
    required => 1
);

=head2 languages

language array, set this if you want to test specific language only

=cut

has languages => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] });

has _status => (
    is       => 'rw',
    isa      => 'HashRef',
    lazy     => 1,
    init_arg => undef,
    build    => '_build_status'
);

sub _build_status {
    return {
        status   => 1,
        errors   => [],
        warnings => []};
}

sub BUILD {
    my $self = shift;

    unless (scalar @{$self->languages}) {
        my @lang = sort do {
            if (opendir my $dh, $self->directory) {
                grep { s/^(\w+)\.po$/$1/ } readdir $dh;
            } else {
                ();
            }
        };
        $self->languages(\@lang);
    }

    Locale::Maketext::ManyPluralForms->import({
            '_encoding' => 'utf-8',
            '*'         => ['Gettext' => File::Spec->rel2abs($self->directory) . '/*.po']});
}

sub testlocales {
    my $self = shift;

    foreach my $lang (@{$self->languages}) {
        my $po  = _get_po $lang;
        my $lg  = $po->{header}->{language};
        my $hnd = Locale::Maketext::ManyPluralForms::handle_for($lg);
        $hnd->plural(1, 'test');

        my $plural_sub = $hnd->{_plural};

        my $nplurals = 2;    # default
        $nplurals = $1 if $po->{header}->{'plural-forms'} =~ /\bnplurals=(\d+);/;
        my @plural;

        for (my ($i, $j) = (0, $nplurals); $i < 10000 && $j > 0; $i++) {
            my $pos = $plural_sub->($i);
            unless (defined $plural[$pos]) {
                $plural[$pos] = $i;
                $j--;
            }
        }

        # $lang_plural_is_like_english==1 means the language has exactly 2 plural forms
        # and singular is applied only to the quantity of 1. That means something like
        # %plural(%d,ein Stern,%d Sterne) is allowed. In French for instance, singular is
        # also applied to the quantity of 0. In that case the singular form should also
        # contain a %d sequence.
        my $lang_plural_is_like_english = ($nplurals == 2);
        if ($lang_plural_is_like_english) {
            for (my $i = 0; $i <= 100_000; $i++) {
                next if $i == 1;
                if ($plural_sub->($i) == 0) {
                    $lang_plural_is_like_english = 0;
                    last;
                }
            }
        }

        my $ln;

        $plural_sub = $hnd->can('plural');
        my $mock = Test::MockModule->new(ref($hnd), no_auto => 1);
        $mock->mock(
            plural => sub {
                # The plural call should provide exactly the number of forms required by the language
                push @{$self->_status->{errors}},
                    $self->_format_message($lg, $ln, "\%plural() requires $nplurals parameters for this language (provided: @{[@_ - 2]})")
                    unless @_ == $nplurals + 2;

                # %plural() can be used like
                #
                #     %plural(%3,word,words)
                #
                # or like
                #
                #     %plural(%3,%d word,%d words)
                #
                # In the first case we are only looking for the correct plural form
                # providing the actual quantity elsewhere.
                #
                # The code below checks that either all parameters of the current call contain %d
                # or none of them. That means something like %plural(%15,one word,%d words) is an
                # error as singular is in many languages also applied to other quantities than 1.

                my $found_percent_d = 0;
                my @no_percent_d;
                for (my $i = 2; $i < @_; $i++) {
                    if ($_[$i] =~ /%d/) {
                        $found_percent_d++;
                    } else {
                        # $i==2 means it's the singular parameter. This one is allowed to not contain
                        # %d if the language is like English
                        push @no_percent_d, $i - 1 unless ($i == 2 and $lang_plural_is_like_english);
                    }
                }
                if ($found_percent_d) {
                    if (@no_percent_d > 1) {
                        my $s = join(', ', @no_percent_d[0 .. $#no_percent_d - 1]) . ' and ' . $no_percent_d[-1];
                        push @{$self->_status->{errors}}, $self->_format_message($lg, $ln, "\%plural() parameters $s miss %d");
                    } elsif (@no_percent_d == 1) {
                        push @{$self->_status->{errors}}, $self->_format_message($lg, $ln, "\%plural() parameter $no_percent_d[0] misses %d");
                    }
                }

                goto $plural_sub;
            });

        for my $test (@{$po->{ids}}) {
            $ln = $test->[3];
            my $i     = 0;
            my $j     = 0;
            my @param = map {
                $j++;
                push @{$self->_status->{warnings}}, $self->_format_message($lg, $ln, "unused parameter \%$j") if (not defined $_ and $self->debug);
                defined $_ && $_ eq 'text' ? 'text' . $i++ : 1;
            } @{$test->[1]};
            try {
                local $SIG{__WARN__} = sub { die $_[0] };
                $hnd->maketext($test->[0], @param);
            }
            catch {
                if (/Can't locate object method "([^"]+)" via package/) {
                    push @{$self->_status->{errors}}, $self->_format_message($lg, $ln, "Unknown directive \%$1()");
                } else {
                    push @{$self->_status->{errors}}, $self->_format_message($lg, $ln, "Unexpected error:\n$_");
                }
            };
        }
    }

    return $self->_status;
}

sub _cstring {
    my %map = (
        'a' => "\007",
        'b' => "\010",
        't' => "\011",
        'n' => "\012",
        'v' => "\013",
        'f' => "\014",
        'r' => "\015",
    );
    return $_[0] =~ s/
                         \\
                         (?:
                             ([0-7]{1,3})
                         |
                             x([0-9a-fA-F]{1,2})
                         |
                             ([\\'"?abfvntr])
                         )
                     /$1 ? chr(oct($1)) : $2 ? chr(hex($2)) : ($map{$3} || $3)/regx;
}

sub _bstring {
    my @params;
    return $_[0] =~ s!
                         (?>                       # matches %func(%N,parameters...)
                             %
                             (?<func>\w+)
                             \(
                             %
                             (?<p0>[0-9]+)
                             (?<prest>[^\)]*)
                             \)
                         )
                     |
                         (?>                       # matches %func(parameters)
                             %
                             (?<simplefunc>\w+)
                             \(
                             (?<simpleparm>[^\)]*)
                             \)
                         )
                     |                             # matches %N
                         %
                         (?<simple>[0-9]+)
                     |                             # [, ] and ~ should be escaped as ~[, ~] and ~~
                         (?<esc>[\[\]~])
                     !
                         if ($+{esc}) {
                             "~$+{esc}";
                         } elsif ($+{simplefunc}) {
                             "[$+{simplefunc},$+{simpleparm}]";
                         } else {
                             my $pos = ($+{func} ? $+{p0} : $+{simple}) - 1;
                             $params[$pos] = $+{func} && $+{func} eq 'plural' ? 'plural' : ($params[$pos] // 'text');
                             $+{func} ? "[$+{func},_$+{p0}$+{prest}]" : "[_$+{simple}]";
                         }
                     !regx, \@params;
}

{
    my @stack;

    sub _nextline {
        return pop @stack if @stack;
        return scalar readline $_[0];
    }

    sub _unread {
        push @stack, @_;
    }
}

sub _get_trans {
    my $f = shift;

    while (defined(my $l = _nextline $f)) {
        if ($l =~ /^\s*msgstr\s*"(.*)"/) {
            my $line = $1;
            while (defined($l = _nextline $f)) {
                if ($l =~ /^\s*"(.*)"/) {
                    $line .= $1;
                } else {
                    _unread $l;
                    return _cstring($line);
                }
            }
            return _cstring($line);
        }
    }
}

sub _get_po {
    my $lang        = shift;
    my $header_only = shift;

    my %header, @ids, $ln;
    my $first = 1;

    open my $f, '<:utf8', $lang or die "Cannot open $lang: $!\n";
    READ:
    while (defined(my $l = _nextline $f)) {
        if ($l =~ /^\s*msgid\s*"(.*)"/) {
            my $line = $1;
            $ln = $.;
            while (defined($l = _nextline $f)) {
                if ($l =~ /^\s*"(.*)"/) {
                    $line .= $1;
                } else {
                    _unread $l;
                    if ($first) {
                        undef $first;
                        %header = map { split /\s*:\s*/, lc($_), 2 } split /\n/, _get_trans($f);
                        last READ if $header_only;
                    } elsif (length $line) {
                        push @ids, [_bstring(_cstring($line)), _get_trans($f), $ln];
                    }
                    last;
                }
            }
        }
    }

    return {
        header => \%header,
        ids    => \@ids,
        lang   => $header{language},
        file   => $lang,
    };
}

sub _format_message {
    my ($self, $lang, $line, $message) = @_;
    $self->_status->{status} = 0;
    return encode('utf-8', "(lang=$lg, line=$ln): $message");
}

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Binary.com, C<< <binary at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-locale-maketext-test at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Locale-Maketext-Test>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::Maketext::Test


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Maketext-Test>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Locale-Maketext-Test>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Locale-Maketext-Test>

=item * Search CPAN

L<http://search.cpan.org/dist/Locale-Maketext-Test/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Binary.com.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Locale::Maketext::Test
