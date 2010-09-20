#!/usr/bin/perl

##############################################################################
#
# A simple example of converting some Unicode text to an Excel file using
# Excel::XLSX::Writer.
#
# This example generates some Chinese from a file with BIG5 encoded text.
#
#
# reverse('�'), September 2004, John McNamara, jmcnamara@cpan.org
#

use strict;
use warnings;
use Excel::XLSX::Writer;


my $workbook = Excel::XLSX::Writer->new( 'unicode_big5.xlsx' );

die "Couldn't create new Excel file: $!.\n" unless defined $workbook;

my $worksheet = $workbook->add_worksheet();
$worksheet->set_column( 'A:A', 80 );


my $file = 'unicode_big5.txt';

open FH, '<:encoding(big5)', $file or die "Couldn't open $file: $!\n";

my $row = 0;

while ( <FH> ) {
    next if /^#/;    # Ignore the comments in the sample file.
    chomp;
    $worksheet->write( $row++, 0, $_ );
}


__END__
