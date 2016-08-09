package Locale::Maketext::Test;

use 5.006;
use strict;
use warnings;

use Moose;
use Try::Tiny;
use File::Spec qw(rel2abs);
use Locale::Maketext::ManyPluralForms;

=head1 NAME

Locale::Maketext::Test - The great new Locale::Maketext::Test!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Locale::Maketext::Test;

    my $foo = Locale::Maketext::Test->new({directory => '/tmp/locales'});
    # test particular languages
    Locale::Maketext::Test->new({directory => '/tmp/locales', languages => ['en', 'de']});
    # if you want to output warning add debug flag else it will output errors only
    Locale::Maketext::Test->new({directory => '/tmp/locales', debug => 1});

=head1 SUBROUTINES/METHODS

=head2 debug

set this if you need to print warnings along with errors

=cut

has debug => (
    is      => 'rw',
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
