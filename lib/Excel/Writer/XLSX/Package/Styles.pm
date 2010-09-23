package Excel::Writer::XLSX::Package::Styles;

###############################################################################
#
# Styles - A class for writing the Excel XLSX styles file.
#
# Used in conjunction with Excel::Writer::XLSX
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# Documentation after __END__
#

# perltidy with the following options: -mbl=2 -pt=0 -nola

use 5.010000;
use strict;
use warnings;
use Carp;
use Excel::Writer::XLSX::Package::XMLwriter;

our @ISA     = qw(Excel::Writer::XLSX::Package::XMLwriter);
our $VERSION = '0.01';


###############################################################################
#
# Public and private API methods.
#
###############################################################################


###############################################################################
#
# new()
#
# Constructor.
#
sub new {

    my $class = shift;

    my $self = Excel::Writer::XLSX::Package::XMLwriter->new();

    $self->{_writer}           = undef;
    $self->{_formats}          = undef;
    $self->{_font_count}       = 0;
    $self->{_num_format_count} = 0;
    $self->{_palette}          = [];

    bless $self, $class;

    return $self;
}


###############################################################################
#
# _assemble_xml_file()
#
# Assemble and write the XML file.
#
sub _assemble_xml_file {

    my $self = shift;

    return unless $self->{_writer};

    $self->_write_xml_declaration;

    # Add the style sheet.
    $self->_write_style_sheet();

    # Write the number formats.
    $self->_write_num_fmts();

    # Write the fonts.
    $self->_write_fonts();

    # Write the fills.
    $self->_write_fills();

    # Write the borders element.
    $self->_write_borders();

    # Write the cellStyleXfs element.
    $self->_write_cell_style_xfs();

    # Write the cellXfs element.
    $self->_write_cell_xfs();

    # Write the cellStyles element.
    $self->_write_cell_styles();

    # Write the dxfs element.
    $self->_write_dxfs();

    # Write the tableStyles element.
    $self->_write_table_styles();

    # Close the style sheet tag.
    $self->{_writer}->endTag( 'styleSheet' );

    # Close the XML::Writer object and filehandle.
    $self->{_writer}->end();
    $self->{_writer}->getOutput()->close();
}

###############################################################################
#
# _set_style_properties()
#
# Pass in the Format objects and other properties used to set the styles.
#
sub _set_style_properties {

    my $self = shift;

    $self->{_formats}          = shift;
    $self->{_font_count}       = shift;
    $self->{_num_format_count} = shift;
    $self->{_palette}          = shift;
}


###############################################################################
#
# Internal methods.
#
###############################################################################


###############################################################################
#
# _convert_to_xml_color()
#
# Convert from an Excel internal colour index to a XML style #RRGGBB index
# based on the default or user defined values in the Workbook palette.
#
sub _convert_to_xml_color {

    my $self    = shift;
    my $index   = shift;
    my $palette = $self->{_palette};

    # Adjust the colour index.
    $index -= 8;

    # Palette is passsed in from the Workbook class.
    my @rgb = @{ $palette->[$index] };

    # TODO Add the alpha part to the RGBA.
    return sprintf "FF%02X%02X%02X", @rgb;
}


###############################################################################
#
# XML writing methods.
#
###############################################################################


##############################################################################
#
# _write_style_sheet()
#
# Write the <styleSheet> element.
#
sub _write_style_sheet {

    my $self  = shift;
    my $xmlns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';

    my @attributes = ( 'xmlns' => $xmlns );

    $self->{_writer}->startTag( 'styleSheet', @attributes );
}


##############################################################################
#
# _write_num_fmts()
#
# Write the <numFmts> element.
#
sub _write_num_fmts {

    my $self  = shift;
    my $count = $self->{_num_format_count};

    return unless $count;

    my @attributes = ( 'count' => $count );

    $self->{_writer}->startTag( 'numFmts', @attributes );

    # Write the font elements.
    for my $format ( @{ $self->{_formats} } ) {

        # Ignore formats without font information.
        next unless $format->{_num_format_index} >= 164;
        $self->_write_num_fmt( $format->{_num_format_index},
            $format->{_num_format} );
    }

    $self->{_writer}->endTag( 'numFmts' );
}


##############################################################################
#
# _write_num_fmt()
#
# Write the <numFmt> element.
#
sub _write_num_fmt {

    my $self        = shift;
    my $num_fmt_id  = shift;
    my $format_code = shift;

    my @attributes = (
        'numFmtId'   => $num_fmt_id,
        'formatCode' => $format_code,
    );

    $self->{_writer}->emptyTag( 'numFmt', @attributes );
}


##############################################################################
#
# _write_fonts()
#
# Write the <fonts> element.
#
sub _write_fonts {

    my $self  = shift;
    my $count = $self->{_font_count};

    my @attributes = ( 'count' => $count );

    $self->{_writer}->startTag( 'fonts', @attributes );

    # Write the font elements.
    for my $format ( @{ $self->{_formats} } ) {

        # Ignore formats without font information.
        next unless $format->{_has_font};
        $self->_write_font( $format );
    }

    $self->{_writer}->endTag( 'fonts' );
}


##############################################################################
#
# _write_font()
#
# Write the <font> element.
#
sub _write_font {

    my $self   = shift;
    my $format = shift;

    $self->{_writer}->startTag( 'font' );

    $self->{_writer}->emptyTag( 'b' )       if $format->{_bold};
    $self->{_writer}->emptyTag( 'i' )       if $format->{_italic};
    $self->{_writer}->emptyTag( 'strike' )  if $format->{_font_strikeout};
    $self->{_writer}->emptyTag( 'outline' ) if $format->{_font_outline};
    $self->{_writer}->emptyTag( 'shadow' )  if $format->{_font_shadow};
    $self->{_writer}->emptyTag( 'u' )       if $format->{_underline};

    $self->_write_vert_align( 'superscript' ) if $format->{_font_script} == 1;
    $self->_write_vert_align( 'subscript' )   if $format->{_font_script} == 2;

    $self->{_writer}->emptyTag( 'sz', 'val', $format->{_size} );

    if ( my $color = $format->{_color} ) {
        $color = $self->_convert_to_xml_color( $color );

        $self->_write_color( 'rgb' => $color );
    }
    else {
        $self->_write_color( 'theme' => 1 );
    }

    $self->{_writer}->emptyTag( 'name',   'val', $format->{_font} );
    $self->{_writer}->emptyTag( 'family', 'val', $format->{_font_family} );

    if ( $format->{_font} eq 'Calibri' ) {
        $self->{_writer}->emptyTag( 'scheme', 'val', $format->{_font_scheme} );
    }

    $self->{_writer}->endTag( 'font' );
}


##############################################################################
#
# _write_vert_align()
#
# Write the <vertAlign> font sub-element.
#
sub _write_vert_align {

    my $self = shift;
    my $val  = shift;

    my @attributes = ( 'val' => $val );

    $self->{_writer}->emptyTag( 'vertAlign', @attributes );
}


##############################################################################
#
# _write_color()
#
# Write the <color> element.
#
sub _write_color {

    my $self  = shift;
    my $name  = shift;
    my $value = shift;

    my @attributes = ( $name => $value );

    $self->{_writer}->emptyTag( 'color', @attributes );
}


##############################################################################
#
# _write_fills()
#
# Write the <fills> element.
#
sub _write_fills {

    my $self  = shift;
    my $count = 2;

    my @attributes = ( 'count' => $count );

    $self->{_writer}->startTag( 'fills', @attributes );

    # Write the fill elementa.
    $self->_write_fill( 'none' );
    $self->_write_fill( 'gray125' );

    $self->{_writer}->endTag( 'fills' );
}


##############################################################################
#
# _write_fill()
#
# Write the <fill> element.
#
sub _write_fill {

    my $self         = shift;
    my $pattern_type = shift;

    $self->{_writer}->startTag( 'fill' );

    $self->{_writer}->emptyTag( 'patternFill', 'patternType', $pattern_type );

    $self->{_writer}->endTag( 'fill' );
}


##############################################################################
#
# _write_borders()
#
# Write the <borders> element.
#
sub _write_borders {

    my $self  = shift;
    my $count = 1;

    my @attributes = ( 'count' => $count );

    $self->{_writer}->startTag( 'borders', @attributes );

    # Write the border element.
    $self->_write_border();

    $self->{_writer}->endTag( 'borders' );
}


##############################################################################
#
# _write_border()
#
# Write the <border> element.
#
sub _write_border {

    my $self = shift;
    $self->{_writer}->startTag( 'border' );

    $self->{_writer}->emptyTag( 'left' );
    $self->{_writer}->emptyTag( 'right' );
    $self->{_writer}->emptyTag( 'top' );
    $self->{_writer}->emptyTag( 'bottom' );
    $self->{_writer}->emptyTag( 'diagonal' );

    $self->{_writer}->endTag( 'border' );
}


##############################################################################
#
# _write_cell_style_xfs()
#
# Write the <cellStyleXfs> element.
#
sub _write_cell_style_xfs {

    my $self  = shift;
    my $count = 1;

    my @attributes = ( 'count' => $count );

    $self->{_writer}->startTag( 'cellStyleXfs', @attributes );

    # Write the style_xf element.
    $self->_write_style_xf();

    $self->{_writer}->endTag( 'cellStyleXfs' );
}


##############################################################################
#
# _write_cell_xfs()
#
# Write the <cellXfs> element.
#
sub _write_cell_xfs {

    my $self    = shift;
    my @formats = @{ $self->{_formats} };
    my $count   = scalar @formats;

    my @attributes = ( 'count' => $count );

    $self->{_writer}->startTag( 'cellXfs', @attributes );

    # Write the xf elements.
    for my $format ( @formats ) {
        $self->_write_xf( $format );
    }

    $self->{_writer}->endTag( 'cellXfs' );
}


##############################################################################
#
# _write_style_xf()
#
# Write the style <xf> element.
#
sub _write_style_xf {

    my $self       = shift;
    my $num_fmt_id = 0;
    my $font_id    = 0;
    my $fill_id    = 0;
    my $border_id  = 0;

    my @attributes = (
        'numFmtId' => $num_fmt_id,
        'fontId'   => $font_id,
        'fillId'   => $fill_id,
        'borderId' => $border_id,
    );

    $self->{_writer}->emptyTag( 'xf', @attributes );
}


##############################################################################
#
# _write_xf()
#
# Write the <xf> element.
#
sub _write_xf {

    my $self       = shift;
    my $format     = shift;
    my $num_fmt_id = $format->{_num_format_index};
    my $font_id    = $format->{_font_index};
    my $fill_id    = 0;
    my $border_id  = 0;
    my $xf_id      = 0;

    my @attributes = (
        'numFmtId' => $num_fmt_id,
        'fontId'   => $font_id,
        'fillId'   => $fill_id,
        'borderId' => $border_id,
        'xfId'     => $xf_id,
    );

    # Add applyNumberFormat attribute if XF format uses a number format.
    if ( $format->{_num_format_index} > 0 ) {
        push @attributes, ( 'applyNumberFormat' => 1 );
    }

    # Add applyFont attribute if XF format uses a font element.
    if ( $format->{_has_font} && $format->{_font_index} > 0 ) {
        push @attributes, ( 'applyFont' => 1 );
    }

    $self->{_writer}->emptyTag( 'xf', @attributes );

}


##############################################################################
#
# _write_cell_styles()
#
# Write the <cellStyles> element.
#
sub _write_cell_styles {

    my $self  = shift;
    my $count = 1;

    my @attributes = ( 'count' => $count );

    $self->{_writer}->startTag( 'cellStyles', @attributes );

    # Write the cellStyle element.
    $self->_write_cell_style();

    $self->{_writer}->endTag( 'cellStyles' );
}


##############################################################################
#
# _write_cell_style()
#
# Write the <cellStyle> element.
#
sub _write_cell_style {

    my $self       = shift;
    my $name       = 'Normal';
    my $xf_id      = 0;
    my $builtin_id = 0;

    my @attributes = (
        'name'      => $name,
        'xfId'      => $xf_id,
        'builtinId' => $builtin_id,
    );

    $self->{_writer}->emptyTag( 'cellStyle', @attributes );
}


##############################################################################
#
# _write_dxfs()
#
# Write the <dxfs> element.
#
sub _write_dxfs {

    my $self  = shift;
    my $count = 0;

    my @attributes = ( 'count' => $count );

    $self->{_writer}->emptyTag( 'dxfs', @attributes );
}


##############################################################################
#
# _write_table_styles()
#
# Write the <tableStyles> element.
#
sub _write_table_styles {

    my $self                = shift;
    my $count               = 0;
    my $default_table_style = 'TableStyleMedium9';
    my $default_pivot_style = 'PivotStyleLight16';

    my @attributes = (
        'count'             => $count,
        'defaultTableStyle' => $default_table_style,
        'defaultPivotStyle' => $default_pivot_style,
    );

    $self->{_writer}->emptyTag( 'tableStyles', @attributes );
}


1;


__END__

=pod

=head1 NAME

Styles - A class for writing the Excel XLSX styles file.

=head1 SYNOPSIS

See the documentation for L<Excel::Writer::XLSX>.

=head1 DESCRIPTION

This module is used in conjunction with L<Excel::Writer::XLSX>.

=head1 AUTHOR

John McNamara jmcnamara@cpan.org

=head1 COPYRIGHT

� MM-MMX, John McNamara.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.

=head1 LICENSE

Either the Perl Artistic Licence L<http://dev.perl.org/licenses/artistic.html> or the GPL L<http://www.opensource.org/licenses/gpl-license.php>.

=head1 DISCLAIMER OF WARRANTY

See the documentation for L<Excel::Writer::XLSX>.

=cut
