#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

#######################################################################
#
# chartex - A utility to extract charts from an Excel file for
# insertion into a WriteExcel file.
#
# reverse('ｩ'), September 2007, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
# Documentation after __END__
#

require 'writeexcel'

class Chartex
  attr_reader :file

  def initialize(file = nil)
    @file       = file
    @sheetnames = Array.new
    @exrefs     = Array.new
    @buf        = StringIO.new
  end

  def set_file(file)
    @file = file
  end

  def get_workbook(file = nil)
    file ||= @file
    ole = OLEStorageLite.new(file)
    book97 = 'Workbook'.unpack('C*').pack('v*')
    workbook = ole.getPpsSearch([book97], 1, 1)[0]
    @buf.write(workbook.data)
    @buf.rewind
    workbook
  end
end

# main

if $0 == __FILE__

end

=begin
my $man         = 0;
my $help        = 0;
my $in_chart    = 0;
my $chart_name  = 'chart';
my $chart_index = 1;
my $sheet_index = -1;
my @sheetnames;
my @exrefs;
my $depth_count = 0;
my $max_font    = 0;

#
# Do the Getopt and Pod::Usage routines.
#
GetOptions(
            'help|?'    => \$help,
            'man'       => \$man,
            'chart=s'   => \$chart_name,
          ) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;


# From the Pod::Usage pod:
# If no arguments were given, then allow STDIN to be used only
# if it's not connected to a terminal (otherwise print usage)
pod2usage() if @ARGV == 0 && -t STDIN;




# Check that the file can be opened because OLE::Storage_Lite won't tell us.
# Possible race condition here. Could fix with latest OLE::Storage_Lite. TODO.
#
my $file = $ARGV[0];

open  TMP, $file or die "Couldn't open $file. $!\n";
close TMP;

my $ole      = OLE::Storage_Lite->new($file);
my $book97   = pack 'v*', unpack 'C*', 'Workbook';
my $workbook = ($ole->getPpsSearch([$book97], 1, 1))[0];

die "Couldn't find Excel97 data in file $file.\n" unless $workbook;


# Write the data to a file so that we can access it with read().
my $tmpfile = IO::File->new_tmpfile();
binmode $tmpfile;

my $biff = $workbook->{Data};
print {$tmpfile} $biff;
seek $tmpfile, 0, 0;



my $header;
my $data;

# Read the file record by record and look for a chart BOF record.
#
while (read $tmpfile, $header, 4) {

    my ($record, $length) = unpack "vv", $header;
    next unless $record;

    read $tmpfile, $data, $length;

    # BOUNDSHEET
    if ($record == 0x0085) {
        push @sheetnames, substr $data, 8;
    }

    # EXTERNSHEET
    if ($record == 0x0017) {
        my $count = unpack 'v', $data;

        for my $i (1 .. $count) {
            my @tmp = unpack 'vvv', substr($data, 2 +6*($i-1));
            push @exrefs, [@tmp];
        }

    }

    # BOF
    if ($record == 0x0809) {
        my $type = unpack 'xx v', $data;

        if ($type == 0x0020) {
            my $filename = sprintf "%s%02d.bin", $chart_name, $chart_index;
            open    CHART, ">$filename" or die "Couldn't open $filename: $!";
            binmode CHART;

            my $sheet_name = $sheetnames[$sheet_index];
            $sheet_name .= ' embedded' if $depth_count;

            printf "\nExtracting \%s\ to %s", $sheet_name, $filename;
            $in_chart = 1;
            $chart_index++;
        }
        $depth_count++;
    }


    # FBI, Chart fonts
    if ($record == 0x1060) {

        my $index = substr $data, 8, 2, '';
           $index = unpack 'v', $index;

        # Ignore the inbuilt fonts.
        if ($index >= 5) {
            $max_font = $index if $index > $max_font;

            # Shift index past S::WE fonts
            $index += 2;
        }

        $data .= pack 'v', $index;
    }

    # FONTX, Chart fonts
    if ($record == 0x1026) {

        my $index = unpack 'v', $data;

        # Ignore the inbuilt fonts.
        if ($index >= 5) {
            $max_font = $index if $index > $max_font;

            # Shift index past S::WE fonts
            $index += 2;
        }

        $data = pack 'v', $index;
    }



    if ($in_chart) {
        print CHART $header, $data;
    }


    # EOF
    if ($record == 0x000A) {
            $in_chart = 0;
            $depth_count--;
            $sheet_index++ if $depth_count == 0;
;
    }
}


if ($chart_index > 1) {
    print "\n\n";
    print "Add the following near the start of your program\n";
    print "and change the variable names if required.\n\n";
}
else {
    print "\nNo charts found in workbook\n";
}

for my $aref (@exrefs) {
    my $sheet1 = $sheetnames[$aref->[1]];
    my $sheet2 = $sheetnames[$aref->[2]];

    my $range;

    if ($sheet1 ne $sheet2) {
        $range = $sheet1 . ":" .  $sheet2;
    }
    else {
        $range = $sheet1;
    }

    $range = "'$range'" if $range =~ /[^\w:]/;

    print "    \$worksheet->store_formula('=$range!A1');\n";
}

print "\n";

for my $i (5 .. $max_font) {

    printf "    my \$chart_font_%d = \$workbook->add_format(font_only => 1);\n",
                $i -4;

}





__END__


=head1 NAME

chartex - A utility to extract charts from an Excel file for insertion into a Spreadsheet::WriteExcel file.

=head1 DESCRIPTION

This program is used for extracting one or more charts from an Excel file in binary format. The charts can then be included in a C<Spreadsheet::WriteExcel> file.

See the C<add_chart_ext()> section of the  Spreadsheet::WriteExcel documentation for more details.


=head1 SYNOPSIS

chartex [--chartname --help --man] file.xls

    Options:
        --chartname -c  The root name for the extracted charts,
                        defaults to "chart".


=head1 OPTIONS

=over 4

=item B<--chartname or -c>

This sets the root name for the extracted charts, defaults to "chart". For example:

    $ chartex file.xls

    Extracting "Chart1" to chart01.bin


    $ chartex -c mychart file.xls

    Extracting "Chart1" to mychart01.bin

=item B<--help or -h>

Print a brief help message and exits.


=item B<--man or -m>

Prints the manual page and exits.

=back


=head1 AUTHOR

John McNamara jmcnamara@cpan.org


=head1 VERSION

Version 0.02.


=head1 COPYRIGHT

ｩ MMV, John McNamara.

All Rights Reserved. This program is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.


=cut
=end
