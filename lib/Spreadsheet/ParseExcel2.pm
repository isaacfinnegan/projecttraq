# Spreadsheet::ParseExcel2
#  by Kawai, Takanori (Hippo2000) 2000.10.2
#                                 2001. 2.2 (Ver. 0.15)
# This Program is ALPHA version.
#//////////////////////////////////////////////////////////////////////////////
# Spreadsheet::ParseExcel2 Objects
#//////////////////////////////////////////////////////////////////////////////
use Spreadsheet::ParseExcel::FmtDefault;
#==============================================================================
# Spreadsheet::ParseExcel2::Workbook
#==============================================================================
package Spreadsheet::ParseExcel2::Workbook;
require Exporter;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(Exporter);
sub new($) {
  my ($sClass) = @_;
  my $oThis = {};
  bless $oThis, $sClass;
}

#------------------------------------------------------------------------------
# Spreadsheet::ParseExcel2::Workbook->ParseAbort
#------------------------------------------------------------------------------
sub ParseAbort($$) {
    my ($oThis, $sVal) =@_;
    $oThis->{_ParseAbort} = $sVal;
}
#------------------------------------------------------------------------------
# Spreadsheet::ParseExcel2::Workbook->Parse
#------------------------------------------------------------------------------
sub Parse($$;$) {
    my ($sClass, $sFile, $oFmt) =@_;
    my $_oEx = new Spreadsheet::ParseExcel2;
    my $oBook = $_oEx->Parse($sFile, $oFmt);
    $oBook->{_Excel} = $_oEx;
    $oBook;
}
#------------------------------------------------------------------------------
# debug
#------------------------------------------------------------------------------
sub debug {
	my($message) = @_;

	my($package, $filename, $line, $subroutine, $has_args, $wantarray) = caller(1);
	my($my_package, @dummies) = caller(0);
	#$subroutine =~ s/^${my_package}:://;
	my $debug_message = "DEBUG: $subroutine: $message";
	supportingFunctions::log($debug_message, 5);
}
#------------------------------------------------------------------------------
# Spreadsheet::ParseExcel2::Workbook Worksheet
#------------------------------------------------------------------------------
sub Worksheet($$) {
    my ($oBook, $sName) =@_;
    my $oWkS;
    foreach $oWkS (@{$oBook->{Worksheet}}) {
        return $oWkS if($oWkS->{Name} eq $sName);
    }
    if($sName =~ /^\d+$/) {
        return $oBook->{Worksheet}->[$sName];
    }
    return undef;
}
#==============================================================================
# Spreadsheet::ParseExcel2::Worksheet
#==============================================================================
package Spreadsheet::ParseExcel2::Worksheet;
require Exporter;
use strict;
sub sheetNo($);
use overload 
    '0+'        => \&sheetNo,
    'fallback'  => 1,
;
use vars qw($VERSION @ISA);
@ISA = qw(Exporter);
sub new($%) {
  my ($sClass, %rhIni) = @_;
  my $oThis = \%rhIni;

  $oThis->{Cells}=undef;
  $oThis->{DefColWidth}=8.38;
  bless $oThis, $sClass;
}
#------------------------------------------------------------------------------
# Spreadsheet::ParseExcel2::Worksheet->sheetNo
#------------------------------------------------------------------------------
sub sheetNo($){
    my ($oSelf) = @_;
    return $oSelf->{_SheetNo};
}
#------------------------------------------------------------------------------
# Spreadsheet::ParseExcel2::Worksheet->Cell
#------------------------------------------------------------------------------
sub Cell($$$){
    my ($oSelf, $iR, $iC) = @_;

    # return undef if no arguments are given or if no cells are defined
    return  if ((!defined($iR)) || (!defined($iC)) ||
                (!defined($oSelf->{MaxRow})) || (!defined($oSelf->{MaxCol})));
    
    # return undef if outside defined rectangle
    return  if (($iR < $oSelf->{MinRow}) || ($iR > $oSelf->{MaxRow}) ||
                ($iC < $oSelf->{MinCol}) || ($iC > $oSelf->{MaxCol}));
    
    # return the Cell object
    return $oSelf->{Cells}[$iR][$iC];
}
#------------------------------------------------------------------------------
# Spreadsheet::ParseExcel2::Worksheet->RowRange
#------------------------------------------------------------------------------
sub RowRange($){
    my ($oSelf) = @_;
    my $iMin = $oSelf->{MinRow} || 0;
    my $iMax = defined($oSelf->{MaxRow}) ? $oSelf->{MaxRow} : ($iMin-1);

    # return the range
    return($iMin, $iMax);
}
#------------------------------------------------------------------------------
# Spreadsheet::ParseExcel2::Worksheet->ColRange
#------------------------------------------------------------------------------
sub ColRange($){
    my ($oSelf) = @_;
    my $iMin = $oSelf->{MinCol} || 0;
    my $iMax = defined($oSelf->{MaxCol}) ? $oSelf->{MaxCol} : ($iMin-1);

    # return the range
    return($iMin, $iMax);
}

#==============================================================================
# Spreadsheet::ParseExcel2::Font
#==============================================================================
package Spreadsheet::ParseExcel2::Font;
require Exporter;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(Exporter);
sub new($%) {
  my ($sClass, %rhIni) = @_;
  my $oThis = \%rhIni;

  bless $oThis, $sClass;
}
#==============================================================================
# Spreadsheet::ParseExcel2::Format
#==============================================================================
package Spreadsheet::ParseExcel2::Format;
require Exporter;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(Exporter);
sub new($%) {
  my ($sClass, %rhIni) = @_;
  my $oThis = \%rhIni;

  bless $oThis, $sClass;
}
#==============================================================================
# Spreadsheet::ParseExcel2::Cell
#==============================================================================
package Spreadsheet::ParseExcel2::Cell;
require Exporter;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(Exporter);

sub new($%) {
    my ($sPkg, %rhKey)=@_;
    my ($sWk, $iLen);
    my $oThis = \%rhKey;

    bless $oThis, $sPkg;
}

sub Value($){
    my ($oThis)=@_;
    return $oThis->{_Value};
}
#==============================================================================
# Spreadsheet::ParseExcel2
#==============================================================================
package Spreadsheet::ParseExcel2;
require Exporter;
use strict;
use OLE::Storage_Lite;
use vars qw($VERSION @ISA);
@ISA = qw(Exporter);
$VERSION = '0.2603'; # 
my @aColor =
(
    '000000',   # 0x00
    'FFFFFF', 'FFFFFF', 'FFFFFF', 'FFFFFF',
    'FFFFFF', 'FFFFFF', 'FFFFFF', 'FFFFFF', #0x08 - This one's Black, too ???
    'FFFFFF', 'FF0000', '00FF00', '0000FF',
    'FFFF00', 'FF00FF', '00FFFF', '800000', # 0x10
    '008000', '000080', '808000', '800080',
    '008080', 'C0C0C0', '808080', '9999FF', # 0x18
    '993366', 'FFFFCC', 'CCFFFF', '660066',
    'FF8080', '0066CC', 'CCCCFF', '000080', # 0x20
    'FF00FF', 'FFFF00', '00FFFF', '800080',
    '800000', '008080', '0000FF', '00CCFF', # 0x28
    'CCFFFF', 'CCFFCC', 'FFFF99', '99CCFF',
    'FF99CC', 'CC99FF', 'FFCC99', '3366FF', # 0x30
    '33CCCC', '99CC00', 'FFCC00', 'FF9900',
    'FF6600', '666699', '969696', '003366', # 0x38
    '339966', '003300', '333300', '993300',
    '993366', '333399', '333333', 'FFFFFF'  # 0x40
);
use constant verExcel95 => 0x500;
use constant verExcel97 =>0x600;
use constant verBIFF2 =>0x00;
use constant verBIFF3 =>0x02;
use constant verBIFF4 =>0x04;
use constant verBIFF5 =>0x08;
use constant verBIFF8 =>0x18;   #Added (Not in BOOK)

my $CF_RECORD_ID		= 0x1B1;
my $CONDFMT_RECORD_ID	= 0x1B0;

my %ProcTbl =(
#Develpers' Kit P291
    0x14    => \&_subHeader,            # Header
    0x15    => \&_subFooter,            # Footer
    0x18    => \&_subName,              # NAME(?)
    0x1A    => \&_subVPageBreak,        # Veritical Page Break
    0x1B    => \&_subHPageBreak,        # Horizontal Page Break
    0x22    => \&_subFlg1904,           # 1904 Flag
    0x26    => \&_subMergin,            # Left Mergin
    0x27    => \&_subMergin,            # Right Mergin
    0x28    => \&_subMergin,            # Top Mergin
    0x29    => \&_subMergin,            # Bottom Mergin
    0x2A    => \&_subPrintHeaders,      # Print Headers
    0x2B    => \&_subPrintGridlines,    # Print Gridlines
    0x3C    => \&_subContinue,          # Continue
    0x43    => \&_subXF,                # ExTended Format(?)
#Develpers' Kit P292
    0x55   =>\&_subDefColWidth,         # Consider
    0x5C    => \&_subWriteAccess,       # WRITEACCESS
    0x7D    => \&_subColInfo,           # Colinfo
    0x7E    => \&_subRK,                # RK
    0x81    => \&_subWSBOOL,            # WSBOOL
    0x83    => \&_subHcenter,           # HCENTER
    0x84    => \&_subVcenter,           # VCENTER
    0x85    => \&_subBoundSheet,        # BoundSheet

    0x92    => \&_subPalette,           # Palette, fgp

    0x99    => \&_subStandardWidth,     # Standard Col
#Develpers' Kit P293
    0xA1    => \&_subSETUP,             # SETUP
    0xBD    => \&_subMulRK,             # MULRK
    0xBE    => \&_subMulBlank,          # MULBLANK
    0xD6    => \&_subRString,           # RString
#Develpers' Kit P294
    0xE0    => \&_subXF,                # ExTended Format
    0xE5    => \&_subMergeArea,         # MergeArea (Not Documented)
    0xFC    => \&_subSST,               # Shared String Table
    0xFD    => \&_subLabelSST,          # Label SST
#Develpers' Kit P295
    0x201   => \&_subBlank,             # Blank

    0x202   => \&_subInteger,           # Integer(Not Documented)
    0x203   => \&_subNumber,            # Number
    0x204   => \&_subLabel ,            # Label
    0x205   => \&_subBoolErr,           # BoolErr
    0x207   => \&_subString,            # STRING
    0x208   => \&_subRow,               # RowData
    0x221   => \&_subArray,             #Array (Consider)
    0x225   => \&_subDefaultRowHeight,  # Consider


    0x31    => \&_subFont,              # Font
    0x231   => \&_subFont,              # Font

    0x27E   => \&_subRK,                # RK
    0x41E   => \&_subFormat,            # Format

    0x06    => \&_subFormula,           # Formula
    0x406   => \&_subFormula,           # Formula

    0x09    => \&_subBOF,               # BOF(BIFF2)
    0x209   => \&_subBOF,               # BOF(BIFF3)
    0x409   => \&_subBOF,               # BOF(BIFF4)
    0x809   => \&_subBOF,               # BOF(BIFF5-8)

	0x4BC	=> \&_subSharedFormula,

	$CF_RECORD_ID		=> \&_subCF,		# Conditional Formatting Conditions
	$CONDFMT_RECORD_ID	=> \&_subCondFmt,	# Conditional Formatting Ranges
    );

my %RECORD_NAME =(
    0x06    => 'Formula',
    0x09    => 'BOF',
    0x0A    => 'EOF',
    0x0C    => 'CalcCount',
    0x0D    => 'CalcMode',
    0x0E    => 'Precision',
    0x0F    => 'RefMode',
    0x10    => 'Delta',
    0x11    => 'Iteration',
    0x12    => 'Protect',
    0x13    => 'Password',
    0x14    => 'Header',
    0x15    => 'Footer',
    0x18    => 'Name',
    0x19    => 'WindowProtect',
    0x1A    => 'VPageBreak',
    0x1B    => 'HPageBreak',
    0x1D    => 'Selection',
    0x22    => 'Flg1904',
    0x26    => 'Mergin',
    0x27    => 'Mergin',
    0x28    => 'Mergin',
    0x29    => 'Mergin',
    0x2A    => 'PrintHeaders',
    0x2B    => 'PrintGridlines',
    0x3C    => 'Continue',
    0x3D    => 'Window1',
    0x40    => 'Backup',
    0x42    => 'CodeName',
    0x43    => 'XF',
    0x55    => 'DefColWidth',
    0x5C    => 'WriteAccess',
    0x5F    => 'SaveReCalc',
    0x7D    => 'ColInfo',
    0x7E    => 'RK',
    0x80    => 'Guts',
    0x81    => 'WSBOOL',
    0x82    => 'GridSet',
	0x83    => 'Hcenter',
	0x84    => 'Vcenter',
    0x85    => 'BoundSheet',
    0x8C    => 'Country',
    0x8D    => 'HideObj',
    0x92    => 'Palette',
    0x99    => 'StandardWidth',
    0x9C    => 'FnGroupCount',
    0xA1    => 'SETUP',
    0xBD    => 'MulRK',
    0xBE    => 'MulBlank',
    0xC1    => 'MMS: AddMenu/DelMenu',
    0xD6    => 'RString',
    0xD7    => 'DBCell',
    0xDA    => 'BookBool',
    0xE0    => 'XF',
    0xE1    => 'InterfaceHdr',
    0xE2    => 'InterfaceEnd',
    0xE5    => 'MergeArea',
    0xFC    => 'SST',
    0xFD    => 'LabelSST',
    0xFF    => 'ExtSST',
    0x13D   => 'TabID',
    0x160   => 'UseSelfs',
    0x161   => 'DSF: Double Stream File',
    0x1AF   => 'Prot4Rev',
    0x1B7   => 'RefreshAll',
    0x1BC   => 'Prot4RevPass',
    0x200   => 'Dimensions',
    0x201   => 'Blank',
    0x202   => 'Integer',
    0x203   => 'Number',
    0x204   => 'Label ',
    0x205   => 'BoolErr',
    0x207   => 'String',
    0x208   => 'Row',
    0x209   => 'BOF',
    0x20B   => 'Index',
    0x221   => 'Array',
    0x225   => 'DefaultRowHeight',
    0x231   => 'Font',
    0x23E   => 'Window2',
    0x27E   => 'RK',
    0x293   => 'Style',
    0x406   => 'Formula',
    0x409   => 'BOF',
    0x41E   => 'Format',
	0x4BC	=> 'SharedFormula',
    0x809   => 'BOF',
	$CF_RECORD_ID		=> 'CF',
	$CONDFMT_RECORD_ID	=> 'CondFmt',
);


my $BIGENDIAN;
my $PREFUNC;
my $_CellHandler;
my $_NotSetCell;
my $_Object;

#==============================================================================
# Global Constants
#==============================================================================

my($VERBOSE_DEBUG)	= 0;
my($DEBUG)			= 0 || $VERBOSE_DEBUG;
my($COND_FMT_DEBUG) = 0 || $VERBOSE_DEBUG;

my($VALUE_CLASS_OFFSET)	= 0x20;
my($ARRAY)	= 0x40;

my($BEGIN_REF_CLASS, $END_REF_CLASS)		= (0x20, 0x3F);
my($BEGIN_VALUE_CLASS, $END_VALUE_CLASS)	= (0x40, 0x5F);
my($BEGIN_ARRAY_CLASS, $END_ARRAY_CLASS)	= (0x60, 0x7F);

my($ROW_RELATIVE_MASK) = 0x8000;
my($COL_RELATIVE_MASK) = 0x4000;

my($VOLATILE_ATTRIBUTE)			= 0x01;
my($IF_ATTRIBUTE)				= 0x02;
my($CHOOSE_ATTRIBUTE)			= 0x04;
my($SKIP_ATTRIBUTE)				= 0x08;
my($SUM_ATTRIBUTE)				= 0x10;
my($ASSIGN_ATTRIBUTE)			= 0x20;
my($SPACE_ATTRIBUTE)			= 0x40;
my($SPACE_VOLATILE_ATTRIBUTE)	= 0x41;

my(@CF_TYPE_STRINGS) =  (
	"Dummy0",
	"Compare to Cell Value",
	"Evaluate Formula"
);
my(@CF_OPERATOR_STRINGS) = (
	"No Comparison",
	"Between",
	"Not Between",
	"=",
	"<>",
	">",
	"<",
	">=",
	"<="
);

my($CF_LEFT_BORDER_STYLE_AND_COLOR_MODIFIED)	= 0x00000400;
my($CF_RIGHT_BORDER_STYLE_AND_COLOR_MODIFIED)	= 0x00000800;
my($CF_TOP_BORDER_STYLE_AND_COLOR_MODIFIED)		= 0x00001000;
my($CF_BOTTOM_BORDER_STYLE_AND_COLOR_MODIFIED)	= 0x00002000;
my($CF_PATTERN_STYLE_MODIFIED)					= 0x00010000;
my($CF_PATTERN_COLOR_MODIFIED)					= 0x00020000;
my($CF_PATTERN_BACKGROUND_MODIFIED)				= 0x00040000;
my($CF_RECORD_CONTAINS_FONT_FORMATTING_BLOCK)	= 0x04000000;
my($CF_RECORD_CONTAINS_BORDER_FORMATTING_BLOCK)	= 0x10000000;
my($CF_RECORD_CONTAINS_PATTERN_FORMATTING_BLOCK)= 0x20000000;

my($CF_FONT_FORMATTING_BLOCK_SIZE)		= 118;
my($CF_BORDER_FORMATTING_BLOCK_SIZE)	= 8;
my($CF_PATTERN_FORMATTING_BLOCK_SIZE)	= 4;

my(%ADD) = (
	string		=> "+",
	id			=> 0x03,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "ADD"
);
my(%SUBTRACT) = (
	string		=> "-",
	id			=> 0x04,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "SUBTRACT"
);
my(%BOOL) = (
	string		=> "BOOL",
	id			=> 0x1D,
	type		=> "operand",
	size		=> 2,
	num_operands=> 0,
	parser		=> \&parse_bool
);
my(%INT) = (
	string		=> "INT",
	id			=> 0x1E,
	type		=> "operand",
	size		=> 3,
	num_operands=> 0,
	parser		=> \&parse_int
);
my(%DIVIDE) = (
	string		=> "/",
	id			=> 0x06,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "DIVIDE"
);
my(%MULTIPLY) = (
	string		=> "*",
	id			=> 0x05,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "MULTIPLY"
);
my(%POWER) = (
	string		=> "^",
	id			=> 0x07,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "POWER"
);
my(%EQUAL) = (
	string		=> "=",
	id			=> 0x0B,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "EQUAL"
);
my(%GREATER_THAN) = (
	string		=> ">",
	id			=> 0x0D,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "GREATER_THAN"
);
my(%LESS_THAN) = (
	string		=> "<",
	id			=> 0x09,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "LESS_THAN"
);
my(%LESS_EQUAL) = (
	string		=> "<=",
	id			=> 0x1A,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "LESS_EQUAL"
);
my(%GREATER_EQUAL) = (
	string		=> ">=",
	id			=> 0x1C,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "GREATER_EQUAL"
);
my(%NOT_EQUAL) = (
	string		=> "<>",
	id			=> 0x0E,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "NOT_EQUAL"
);
my(%CONCAT) = (
	string		=> "&",
	id			=> 0x08,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "CONCAT"
);
my(%AREA) = (
	string		=> "AREA",
	id			=> 0x25,
	type		=> "operand",
	size		=> 9,
	num_operands=> 0,
	parser		=> \&parse_area
);
my(%AREA_VALUE) = (
	string		=> "AREA_VALUE",
	id			=> ($AREA{id} + $VALUE_CLASS_OFFSET),
	type		=> "operand",
	size		=> $AREA{size},
	num_operands=> $AREA{num_operands},
	parser		=> \&parse_area
);
my(%AREA_ARRAY) = (
	string		=> "AREA_ARRAY",
	id			=> ($AREA{id} + $ARRAY),
	type		=> "operand",
	size		=> $AREA{size},
	num_operands=> $AREA{num_operands},
	parser		=> \&parse_area
);
my(%AREA_N) = (
	string		=> "AREA_N",
	id			=> 0x2D,
	type		=> "operand",
	size		=> 9,
	num_operands=> 0,
	parser		=> \&parse_area_n
);
my(%AREA_N_VALUE) = (
	string		=> "AREA_N_VALUE",
	id			=> ($AREA_N{id} + $VALUE_CLASS_OFFSET),
	type		=> "operand",
	size		=> $AREA_N{size},
	num_operands=> $AREA_N{num_operands},
	parser		=> \&parse_area_n
);
my(%AREA_N_ARRAY) = (
	string		=> "AREA_N_ARRAY",
	id			=> ($AREA_N{id} + $ARRAY),
	type		=> "operand",
	size		=> $AREA_N{size},
	num_operands=> $AREA_N{num_operands},
	parser		=> \&parse_area_n
);
my(%MEM_ERR) = (
	string		=> "MEM_ERR",
	id			=> 0x27,
	type		=> "operand",
	size		=> 7,
	num_operands=> 0,
	parser		=> \&parse_mem_err
);
my(%MEM_ERR_VALUE) = (
	string		=> "MEM_ERR_VALUE",
	id			=> ($MEM_ERR{id} + $VALUE_CLASS_OFFSET),
	type		=> "operand",
	size		=> $MEM_ERR{size},
	num_operands=> $MEM_ERR{num_operands},
	parser		=> \&parse_mem_err
);
my(%MEM_ERR_ARRAY) = (
	string		=> "MEM_ERR_ARRAY",
	id			=> ($MEM_ERR{id} + $ARRAY),
	type		=> "operand",
	size		=> $MEM_ERR{size},
	num_operands=> $MEM_ERR{num_operands},
	parser		=> \&parse_mem_err
);
my(%ATTR) = (
	string		=> "ATTR",
	id			=> 0x19,
	type		=> "control",
	size		=> 4,
	num_operands=> 1,
	parser		=> \&parse_attr,
	to_infix	=> \&attr_to_infix
);
my(%REFERENCE) = (
	string		=> "REFERENCE",
	id			=> 0x24,
	type		=> "operand",
	size		=> 5,
	num_operands=> 1,
	parser		=> \&parse_reference
);
my(%REFERENCE_VALUE) = (
	string		=> "REFERENCE_VALUE",
	id			=> ($REFERENCE{id} + $VALUE_CLASS_OFFSET),
	type		=> "operand",
	size		=> $REFERENCE{size},
	num_operands=> $REFERENCE{num_operands},
	parser		=> \&parse_reference
);
my(%REFERENCE_ARRAY) = (
	string		=> "REFERENCE_ARRAY",
	id			=> ($REFERENCE{id} + $ARRAY),
	type		=> "operand",
	size		=> $REFERENCE{size},
	num_operands=> $REFERENCE{num_operands},
	parser		=> \&parse_reference
);
my(%REFERENCE_N) = (
	string		=> "REFERENCE_N",
	id			=> 0x2C,
	type		=> "operand",
	size		=> 5,
	num_operands=> 1,
	parser		=> \&parse_reference_n
);
my(%REFERENCE_N_VALUE) = (
	string		=> "REFERENCE_N_VALUE",
	id			=> ($REFERENCE_N{id} + $VALUE_CLASS_OFFSET),
	type		=> "operand",
	size		=> $REFERENCE_N{size},
	num_operands=> $REFERENCE_N{num_operands},
	parser		=> \&parse_reference_n
);
my(%REFERENCE_N_ARRAY) = (
	string		=> "REFERENCE_N_ARRAY",
	id			=> ($REFERENCE_N{id} + $ARRAY),
	type		=> "operand",
	size		=> $REFERENCE_N{size},
	num_operands=> $REFERENCE_N{num_operands},
	parser		=> \&parse_reference_n
);
my(%PARENTHESIS) = (
	string		=> "()",
	id			=> 0x15,
	type		=> "control",
	size		=> 1,
	num_operands=> 1,
	debug		=> "PARENTHESIS",
	parser		=> \&parse_parenthesis,
	to_infix	=> \&parenthesis_to_infix
);
my(%MEM_FUNC) = (
	string		=> "MEM_FUNC",
	id			=> 0x29,
	type		=> "control",
	size		=> 3,
	num_operands=> 1,
	parser		=> \&parse_mem_func
);
my(%UNION) = (
	string		=> ",",
	id			=> 0x10,
	type		=> "operator",
	size		=> 1,
	num_operands=> 2,
	to_infix	=> \&binary_operator_to_infix,
	debug		=> "UNION"
);
my(%FUNC) = (
	string		=> "FUNC",
	id			=> 0x21,
	type		=> "operator",
	size		=> 3,
	num_operands=> 1,
	parser		=> \&parse_func,
	to_infix	=> \&func_to_infix
);
my(%FUNC_VALUE) = (
	string		=> "FUNC_VALUE",
	id			=> ($FUNC{id} + $VALUE_CLASS_OFFSET),
	type		=> "operator",
	size		=> $FUNC{size},
	num_operands=> $FUNC{num_operands},
	parser		=> \&parse_func,
	to_infix	=> \&func_to_infix
);
my(%FUNC_ARRAY) = (
	string		=> "FUNC_ARRAY",
	id			=> ($FUNC{id} + $ARRAY),
	type		=> "operator",
	size		=> $FUNC{size},
	num_operands=> $FUNC{num_operands},
	parser		=> \&parse_func,
	to_infix	=> \&func_to_infix
);
my(%FUNC_VAR) = (
	string		=> "FUNC_VAR",
	id			=> 0x22,
	type		=> "operator",
	size		=> 4,
	num_operands=> 1,
	parser		=> \&parse_func_var,
	to_infix	=> \&func_to_infix
);
my(%FUNC_VAR_VALUE) = (
	string		=> "FUNC_VAR_VALUE",
	id			=> ($FUNC_VAR{id} + $VALUE_CLASS_OFFSET),
	type		=> "operator",
	size		=> $FUNC_VAR{size},
	num_operands=> $FUNC_VAR{num_operands},
	parser		=> \&parse_func_var,
	to_infix	=> \&func_to_infix
);
my(%FUNC_VAR_ARRAY) = (
	string		=> "FUNC_VAR_ARRAY",
	id			=> ($FUNC_VAR{id} + $ARRAY),
	type		=> "operator",
	size		=> $FUNC_VAR{size},
	num_operands=> $FUNC_VAR{num_operands},
	parser		=> \&parse_func_var,
	to_infix	=> \&func_to_infix
);
my(%NUMBER) = (
	string		=> "NUMBER",
	id			=> 0x1F,
	type		=> "operand",
	size		=> 9,
	num_operands=> 1,
	parser		=> \&parse_number
);
my(%STRING) = (
	string		=> "STRING",
	id			=> 0x17,
	type		=> "operand",
	size		=> 9,
	num_operands=> 1,
	parser		=> \&parse_string
);
my(%NAME) = (
	string		=> "NAME",
	id			=> 0x23,
	type		=> "operand",
	size		=> 5,
	num_operands=> 1,
	parser		=> \&parse_name
);
my(%NAME_VALUE) = (
	string		=> "NAME_VALUE",
	id			=> ($NAME{id} + $VALUE_CLASS_OFFSET),
	type		=> "operand",
	size		=> $NAME{size},
	num_operands=> $NAME{num_operands},
	parser		=> \&parse_name
);
my(%NAME_ARRAY) = (
	string		=> "NAME_ARRAY",
	id			=> ($NAME{id} + $ARRAY),
	type		=> "operand",
	size		=> $NAME{size},
	num_operands=> $NAME{num_operands},
	parser		=> \&parse_name
);
my(%NAME_X) = (
	string		=> "NAME_X",
	id			=> 0x39,
	type		=> "operand",
	size		=> 7,
	num_operands=> 1,
	parser		=> \&parse_name_x
);
my(%NAME_X_VALUE) = (
	string		=> "NAME_X_VALUE",
	id			=> ($NAME_X{id} + $VALUE_CLASS_OFFSET),
	type		=> "operand",
	size		=> $NAME_X{size},
	num_operands=> $NAME_X{nun_operands},
	parser		=> \&parse_name_x
);
my(%NAME_X_ARRAY) = (
	string		=> "NAME_X_ARRAY",
	id			=> ($NAME_X{id} + $ARRAY),
	type		=> "operand",
	size		=> $NAME_X{size},
	num_operands=> $NAME_X{nun_operands},
	parser		=> \&parse_name_x
);
my(%EXP) = (
	string		=> "EXP",
	id			=> 0x01,
	type		=> "control",
	size		=> 5,
	num_operands=> 2,
	parser		=> \&parse_exp
);
my(%AREA_3D) = (
	string		=> "AREA_3D",
	id			=> 0x3B,
	type		=> "operand",
	size		=> 11,
	num_operands=> 1,
	parser		=> \&parse_area_3d
);
my(%AREA_3D_VALUE) = (
	string		=> "AREA_3D_VALUE",
	id			=> ($AREA_3D{id} + $VALUE_CLASS_OFFSET),
	type		=> "operand",
	size		=> $AREA_3D{size},
	num_operands=> $AREA_3D{num_operands},
	parser		=> \&parse_area_3d
);
my(%AREA_3D_ARRAY) = (
	string		=> "AREA_3D_ARRAY",
	id			=> ($AREA_3D{id} + $ARRAY),
	type		=> "operand",
	size		=> $AREA_3D{size},
	num_operands=> $AREA_3D{num_operands},
	parser		=> \&parse_area_3d
);
my(%REF_3D) = (
	string		=> "REF_3D",
	id			=> 0x3A,
	type		=> "operand",
	size		=> 7,
	num_operands=> 1,
	parser		=> \&parse_ref_3d
);
my(%REF_3D_VALUE) = (
	string		=> "REF_3D_VALUE",
	id			=> ($REF_3D{id} + $VALUE_CLASS_OFFSET),
	type		=> "operand",
	size		=> $REF_3D{size},
	num_operands=> $REF_3D{num_operands},
	parser		=> \&parse_ref_3d
);
my(%REF_3D_ARRAY) = (
	string		=> "REF_3D_ARRAY",
	id			=> ($REF_3D{id} + $ARRAY),
	type		=> "operand",
	size		=> $REF_3D{size},
	num_operands=> $REF_3D{num_operands},
	parser		=> \&parse_ref_3d
);
my(%MISSING_ARG) = (
	string		=> " ",
	id			=> 0x16,
	type		=> "operand",
	size		=> 1,
	num_operands=> 1,
	debug		=> "MISSING_ARG",
);
my(%UNARY_PLUS) = (
	string		=> "+",
	id			=> 0x12,
	type		=> "operator",
	size		=> 1,
	num_operands=> 1,
	to_infix	=> \&unary_operator_to_infix,
	debug		=> "UNARY_PLUS"
);
my(%UNARY_MINUS) = (
	string		=> "-",
	id			=> 0x13,
	type		=> "operator",
	size		=> 1,
	num_operands=> 1,
	to_infix	=> \&unary_operator_to_infix,
	debug		=> "UNARY_MINUS"
);

my(%UNKNOWN) = (
	string		=> "?",
	id			=> 0xFF,
	size		=> 1,
	debug		=> "<UNKNOWN>"
);

my(%PTG) = (
	$ADD{id}			=> \%ADD,
	$SUBTRACT{id}		=> \%SUBTRACT,
	$BOOL{id}			=> \%BOOL,
	$INT{id}			=> \%INT,
	$DIVIDE{id}			=> \%DIVIDE,
	$MULTIPLY{id}		=> \%MULTIPLY,
	$POWER{id}			=> \%POWER,
	$EQUAL{id}			=> \%EQUAL,
	$GREATER_THAN{id}	=> \%GREATER_THAN,
	$LESS_THAN{id}		=> \%LESS_THAN,
	$LESS_EQUAL{id}		=> \%LESS_EQUAL,
	$GREATER_EQUAL{id}	=> \%GREATER_EQUAL,
	$NOT_EQUAL{id}		=> \%NOT_EQUAL,
	$CONCAT{id}			=> \%CONCAT,
	$AREA{id}			=> \%AREA,
	$AREA_VALUE{id}		=> \%AREA_VALUE,
	$AREA_ARRAY{id}		=> \%AREA_ARRAY,
	$MEM_ERR{id}		=> \%MEM_ERR,
	$MEM_ERR_VALUE{id}	=> \%MEM_ERR_VALUE,
	$MEM_ERR_ARRAY{id}	=> \%MEM_ERR_ARRAY,
	$ATTR{id}			=> \%ATTR,
	$REFERENCE{id}		=> \%REFERENCE,
	$REFERENCE_VALUE{id}=> \%REFERENCE_VALUE,
	$REFERENCE_ARRAY{id}=> \%REFERENCE_ARRAY,
	$REFERENCE_N{id}		=> \%REFERENCE_N,
	$REFERENCE_N_VALUE{id}	=> \%REFERENCE_N_VALUE,
	$REFERENCE_N_ARRAY{id}	=> \%REFERENCE_N_ARRAY,
	$PARENTHESIS{id}	=> \%PARENTHESIS,
	$MEM_FUNC{id}		=> \%MEM_FUNC,
	$UNION{id}			=> \%UNION,
	$FUNC{id}			=> \%FUNC,
	$FUNC_VALUE{id}		=> \%FUNC_VALUE,
	$FUNC_ARRAY{id}		=> \%FUNC_ARRAY,
	$FUNC_VAR{id}		=> \%FUNC_VAR,
	$FUNC_VAR_VALUE{id}	=> \%FUNC_VAR_VALUE,
	$FUNC_VAR_ARRAY{id}	=> \%FUNC_VAR_ARRAY,
	$NUMBER{id}			=> \%NUMBER,
	$STRING{id}			=> \%STRING,
	$NAME{id}			=> \%NAME,
	$NAME_VALUE{id}		=> \%NAME_VALUE,
	$NAME_ARRAY{id}		=> \%NAME_ARRAY,
	$NAME_X{id}			=> \%NAME_X,
	$NAME_X_VALUE{id}	=> \%NAME_X_VALUE,
	$NAME_X_ARRAY{id}	=> \%NAME_X_ARRAY,
	$EXP{id}			=> \%EXP,
	$AREA_3D{id}		=> \%AREA_3D,
	$AREA_3D_VALUE{id}	=> \%AREA_3D_VALUE,
	$AREA_3D_ARRAY{id}	=> \%AREA_3D_ARRAY,
	$REF_3D{id}			=> \%REF_3D,
	$REF_3D_VALUE{id}	=> \%REF_3D_VALUE,
	$REF_3D_ARRAY{id}	=> \%REF_3D_ARRAY,
	$MISSING_ARG{id}	=> \%MISSING_ARG,
	$UNARY_PLUS{id}		=> \%UNARY_PLUS,
	$UNARY_MINUS{id}	=> \%UNARY_MINUS
);

#	Microsoft Excel Functions
my @FUNCTION_NAME = (
	"COUNT",
	"IF",
	"ISNA",
	"ISERROR",
	"SUM",
	"AVERAGE",
	"MIN",
	"MAX",
	"ROW",
	"COLUMN",
	"NA",
	"NPV",
	"STDEV",
	"DOLLAR",
	"FIXED",
	"SIN",
	"COS",
	"TAN",
	"ATAN",
	"PI",
	"SQRT",
	"EXP",
	"LN",
	"LOG10",
	"ABS",
	"INT",
	"SIGN",
	"ROUND",
	"LOOKUP",
	"INDEX",
	"REPT",
	"MID",
	"LEN",
	"VALUE",
	"TRUE",
	"FALSE",
	"AND",
	"OR",
	"NOT",
	"MOD",
	"DCOUNT",
	"DSUM",
	"DAVERAGE",
	"DMIN",
	"DMAX",
	"DSTDEV",
	"VAR",
	"DVAR",
	"TEXT",
	"LINEST",
	"TREND",
	"LOGEST",
	"GROWTH",
	"GOTO",
	"HALT",
	"Dummy55",
	"PV",
	"FV",
	"NPER",
	"PMT",
	"RATE",
	"MIRR",
	"IRR",
	"RAND",
	"MATCH",
	"DATE",
	"TIME",
	"DAY",
	"MONTH",
	"YEAR",
	"WEEKDAY",
	"HOUR",
	"MINUTE",
	"SECOND",
	"NOW",
	"AREAS",
	"ROWS",
	"COLUMNS",
	"OFFSET",
	"ABSREF",
	"RELREF",
	"ARGUMENT",
	"SEARCH",
	"TRANSPOSE",
	"ERROR",
	"STEP",
	"TYPE",
	"ECHO",
	"SETNAME",
	"CALLER",
	"DEREF",
	"WINDOWS",
	"SERIES",
	"DOCUMENTS",
	"ACTIVECELL",
	"SELECTION",
	"RESULT",
	"ATAN2",
	"ASIN",
	"ACOS",
	"CHOOSE",
	"HLOOKUP",
	"VLOOKUP",
	"LINKS",
	"INPUT",
	"ISREF",
	"GETFORMULA",
	"GETNAME",
	"SETVALUE",
	"LOG",
	"EXEC",
	"CHAR",
	"LOWER",
	"UPPER",
	"PROPER",
	"LEFT",
	"RIGHT",
	"EXACT",
	"TRIM",
	"REPLACE",
	"SUBSTITUTE",
	"CODE",
	"NAMES",
	"DIRECTORY",
	"FIND",
	"CELL",
	"ISERR",
	"ISTEXT",
	"ISNUMBER",
	"ISBLANK",
	"T",
	"N",
	"FOPEN",
	"FCLOSE",
	"FSIZE",
	"FREADLN",
	"FREAD",
	"FWRITELN",
	"FWRITE",
	"FPOS",
	"DATEVALUE",
	"TIMEVALUE",
	"SLN",
	"SYD",
	"DDB",
	"GETDEF",
	"REFTEXT",
	"TEXTREF",
	"INDIRECT",
	"REGISTER",
	"CALL",
	"ADDBAR",
	"ADDMENU",
	"ADDCOMMAND",
	"ENABLECOMMAND",
	"CHECKCOMMAND",
	"RENAMECOMMAND",
	"SHOWBAR",
	"DELETEMENU",
	"DELETECOMMAND",
	"GETCHARTITEM",
	"DIALOGBOX",
	"CLEAN",
	"MDETERM",
	"MINVERSE",
	"MMULT",
	"FILES",
	"IPMT",
	"PPMT",
	"COUNTA",
	"CANCELKEY",
	"Dummy171",
	"Dummy172",
	"Dummy173",
	"Dummy174",
	"INITIATE",
	"REQUEST",
	"POKE",
	"EXECUTE",
	"TERMINATE",
	"RESTART",
	"HELP",
	"GETBAR",
	"PRODUCT",
	"FACT",
	"GETCELL",
	"GETWORKSPACE",
	"GETWINDOW",
	"GETDOCUMENT",
	"DPRODUCT",
	"ISNONTEXT",
	"GETNOTE",
	"NOTE",
	"STDEVP",
	"VARP",
	"DSTDEVP",
	"DVARP",
	"TRUNC",
	"ISLOGICAL",
	"DCOUNTA",
	"DELETEBAR",
	"UNREGISTER",
	"Dummy202",
	"Dummy203",
	"USDOLLAR",
	"FINDB",
	"SEARCHB",
	"REPLACEB",
	"LEFTB",
	"RIGHTB",
	"MIDB",
	"LENB",
	"ROUNDUP",
	"ROUNDDOWN",
	"ASC",
	"DBCS",
	"RANK",
	"Dummy217",
	"Dummy218",
	"ADDRESS",
	"DAYS360",
	"TODAY",
	"VDB",
	"Dummy223",
	"Dummy224",
	"Dummy225",
	"Dummy226",
	"MEDIAN",
	"SUMPRODUCT",
	"SINH",
	"COSH",
	"TANH",
	"ASINH",
	"ACOSH",
	"ATANH",
	"DGET",
	"CREATEOBJECT",
	"VOLATILE",
	"LASTERROR",
	"CUSTOMUNDO",
	"CUSTOMREPEAT",
	"FORMULACONVERT",
	"GETLINKINFO",
	"TEXTBOX",
	"INFO",
	"GROUP",
	"GETOBJECT",
	"DB",
	"PAUSE",
	"Dummy249",
	"Dummy250",
	"RESUME",
	"FREQUENCY",
	"ADDTOOLBAR",
	"DELETETOOLBAR",
	"Dummy255",
	"RESETTOOLBAR",
	"EVALUATE",
	"GETTOOLBAR",
	"GETTOOL",
	"SPELLINGCHECK",
	"ERRORTYPE",
	"APPTITLE",
	"WINDOWTITLE",
	"SAVETOOLBAR",
	"ENABLETOOL",
	"PRESSTOOL",
	"REGISTERID",
	"GETWORKBOOK",
	"AVEDEV",
	"BETADIST",
	"GAMMALN",
	"BETAINV",
	"BINOMDIST",
	"CHIDIST",
	"CHIINV",
	"COMBIN",
	"CONFIDENCE",
	"CRITBINOM",
	"EVEN",
	"EXPONDIST",
	"FDIST",
	"FINV",
	"FISHER",
	"FISHERINV",
	"FLOOR",
	"GAMMADIST",
	"GAMMAINV",
	"CEILING",
	"HYPGEOMDIST",
	"LOGNORMDIST",
	"LOGINV",
	"NEGBINOMDIST",
	"NORMDIST",
	"NORMSDIST",
	"NORMINV",
	"NORMSINV",
	"STANDARDIZE",
	"ODD",
	"PERMUT",
	"POISSON",
	"TDIST",
	"WEIBULL",
	"SUMXMY2",
	"SUMX2MY2",
	"SUMX2PY2",
	"CHITEST",
	"CORREL",
	"COVAR",
	"FORECAST",
	"FTEST",
	"INTERCEPT",
	"PEARSON",
	"RSQ",
	"STEYX",
	"SLOPE",
	"TTEST",
	"PROB",
	"DEVSQ",
	"GEOMEAN",
	"HARMEAN",
	"SUMSQ",
	"KURT",
	"SKEW",
	"ZTEST",
	"LARGE",
	"SMALL",
	"QUARTILE",
	"PERCENTILE",
	"PERCENTRANK",
	"MODE",
	"TRIMMEAN",
	"TINV",
	"Dummy333",
	"MOVIECOMMAND",
	"GETMOVIE",
	"CONCATENATE",
	"POWER",
	"PIVOTADDDATA",
	"GETPIVOTTABLE",
	"GETPIVOTFIELD",
	"GETPIVOTITEM",
	"RADIANS",
	"DEGREES",
	"SUBTOTAL",
	"SUMIF",
	"COUNTIF",
	"COUNTBLANK",
	"SCENARIOGET",
	"OPTIONSLISTSGET",
	"ISPMT",
	"DATEDIF",
	"DATESTRING",
	"NUMBERSTRING",
	"ROMAN",
	"OPENDIALOG",
	"SAVEDIALOG",
	"VIEWGET",
	"GETPIVOTDATA",
	"HYPERLINK",
	"PHONETIC",
	"AVERAGEA",
	"MAXA",
	"MINA",
	"STDEVPA",
	"VARPA",
	"STDEVA",
	"VARA"
);
#
#	Number of parameters for each function
#
#	-1 indicates a function with a variable number of parameters
#
#	-2 indicates a function that's actually an Excel command
#
my %FUNCTION_NUM_PARMS = (
	COUNT			=> -1,
	IF				=> -1,
	ISNA			=> 1,
	ISERROR			=> 1,
	SUM				=> -1,
	AVERAGE			=> -1,
	MIN				=> -1,
	MAX				=> -1,
	ROW				=> -1,
	COLUMN			=> -1,
	NA				=> 0,
	NPV				=> -1,
	STDEV			=> -1,
	DOLLAR			=> -1,
	FIXED			=> -1,
	SIN				=> 1,
	COS				=> 1,
	TAN				=> 1,
	ATAN			=> 1,
	PI				=> 0,
	SQRT			=> 1,
	EXP				=> 1,
	LN				=> 1,
	LOG10			=> 1,
	ABS				=> 1,
	INT				=> 1,
	SIGN			=> 1,
	ROUND			=> 2,
	LOOKUP			=> -1,
	INDEX			=> -1,
	REPT			=> 2,
	MID				=> 3,
	LEN				=> 1,
	VALUE			=> 1,
	TRUE			=> 0,
	FALSE			=> 0,
	AND				=> -1,
	OR				=> -1,
	NOT				=> 1,
	MOD				=> 2,
	DCOUNT			=> -1,
	DSUM			=> 3,
	DAVERAGE		=> 3,
	DMIN			=> 3,
	DMAX			=> 3,
	DSTDEV			=> 3,
	VAR				=> -1,
	DVAR			=> 3,
	TEXT			=> 2,
	LINEST			=> -1,
	TREND			=> -1,
	LOGEST			=> -1,
	GROWTH			=> -1,
	GOTO			=> -2,
	HALT			=> -2,
	Dummy55			=> 0,
	PV				=> -1,
	FV				=> -1,
	NPER			=> -1,
	PMT				=> -1,
	RATE			=> -1,
	MIRR			=> 3,
	IRR				=> -1,
	RAND			=> 0,
	MATCH			=> -1,
	DATE			=> 3,
	TIME			=> 3,
	DAY				=> 1,
	MONTH			=> 1,
	YEAR			=> 1,
	WEEKDAY			=> 2,
	HOUR			=> 1,
	MINUTE			=> 1,
	SECOND			=> 1,
	NOW				=> 0,
	AREAS			=> 1,
	ROWS			=> 1,
	COLUMNS			=> 1,
	OFFSET			=> -1,
	ABSREF			=> 0,		# Number of Parameters is Unknown
	RELREF			=> 0,		# Number of Parameters is Unknown
	ARGUMENT		=> -2,
	SEARCH			=> -1,
	TRANSPOSE		=> 1,
	ERROR			=> 1,
	STEP			=> -2,
	TYPE			=> 1,
	ECHO			=> -2,
	SETNAME			=> -2,
	CALLER			=> -2,
	DEREF			=> -2,
	WINDOWS			=> -2,
	SERIES			=> 4,
	DOCUMENTS		=> -2,
	ACTIVECELL		=> -2,
	SELECTION		=> -2,
	RESULT			=> -2,
	ATAN2			=> 2,
	ASIN			=> 1,
	ACOS			=> 1,
	CHOOSE			=> -1,
	HLOOKUP			=> -1,
	VLOOKUP			=> -1,
	LINKS			=> 0,		# Number of Parameters is Unknown
	INPUT			=> -2,
	ISREF			=> 1,
	GETFORMULA		=> -2,
	GETNAME			=> -2,
	SETVALUE		=> -2,
	LOG				=> -1,
	EXEC			=> -2,
	CHAR			=> 1,
	LOWER			=> 1,
	UPPER			=> 1,
	PROPER			=> 1,
	LEFT			=> -1,
	RIGHT			=> -1,
	EXACT			=> 2,
	TRIM			=> 1,
	REPLACE			=> 4,
	SUBSTITUTE		=> -1,
	CODE			=> 1,
	NAMES			=> -2,
	DIRECTORY		=> -2,
	FIND			=> -1,
	CELL			=> 2,
	ISERR			=> 1,
	ISTEXT			=> 1,
	ISNUMBER		=> 1,
	ISBLANK			=> 1,
	T				=> 1,
	N				=> 1,
	FOPEN			=> -2,
	FCLOSE			=> -2,
	FSIZE			=> -2,
	FREADLN			=> -2,
	FREAD			=> -2,
	FWRITELN		=> -2,
	FWRITE			=> -2,
	FPOS			=> -2,
	DATEVALUE		=> 1,
	TIMEVALUE		=> 1,
	SLN				=> 3,
	SYD				=> 4,
	DDB				=> -1,
	GETDEF			=> -2,
	REFTEXT			=> -2,
	TEXTREF			=> -2,
	INDIRECT		=> -1,
	REGISTER		=> -1,
	CALL			=> -1,
	ADDBAR			=> -2,
	ADDMENU			=> -2,
	ADDCOMMAND		=> -2,
	ENABLECOMMAND	=> -2,
	CHECKCOMMAND	=> -2,
	RENAMECOMMAND	=> -2,
	SHOWBAR			=> -2,
	DELETEMENU		=> -2,
	DELETECOMMAND	=> -2,
	GETCHARTITEM	=> -2,
	DIALOGBOX		=> -2,
	CLEAN			=> 1,
	MDETERM			=> 1,
	MINVERSE		=> 1,
	MMULT			=> 2,
	FILES			=> -2,
	IPMT			=> -1,
	PPMT			=> -1,
	COUNTA			=> -1,
	CANCELKEY		=> -2,
	Dummy171		=> 0,
	Dummy172		=> 0,
	Dummy173		=> 0,
	Dummy174		=> 0,
	INITIATE		=> -2,
	REQUEST			=> -2,
	POKE			=> -2,
	EXECUTE			=> -2,
	TERMINATE		=> -2,
	RESTART			=> -2,
	HELP			=> -2,
	GETBAR			=> -2,
	PRODUCT			=> -1,
	FACT			=> 1,
	GETCELL			=> -2,
	GETWORKSPACE	=> -2,
	GETWINDOW		=> -2,
	GETDOCUMENT		=> -2,
	DPRODUCT		=> 3,
	ISNONTEXT		=> 1,
	GETNOTE			=> -2,
	NOTE			=> -2,
	STDEVP			=> -1,
	VARP			=> -1,
	DSTDEVP			=> 3,
	DVARP			=> 3,
	TRUNC			=> -1,
	ISLOGICAL		=> 1,
	DCOUNTA			=> -1,
	DELETEBAR		=> -2,
	UNREGISTER		=> -2,
	Dummy202		=> 0,
	Dummy203		=> 0,
	USDOLLAR		=> -1,
	FINDB			=> -1,
	SEARCHB			=> -1,
	REPLACEB		=> 4,
	LEFTB			=> -1,
	RIGHTB			=> -1,
	MIDB			=> 3,
	LENB			=> 1,
	ROUNDUP			=> -1,
	ROUNDDOWN		=> -1,
	ASC				=> 1,
	DBCS			=> 1,
	RANK			=> -1,
	Dummy217		=> 0,
	Dummy218		=> 0,
	ADDRESS			=> -1,
	DAYS360			=> -1,
	TODAY			=> 0,
	VDB				=> -1,
	Dummy223		=> 0,
	Dummy224		=> 0,
	Dummy225		=> 0,
	Dummy226		=> 0,
	MEDIAN			=> -1,
	SUMPRODUCT		=> -1,
	SINH			=> 1,
	COSH			=> 1,
	TANH			=> 1,
	ASINH			=> 1,
	ACOSH			=> 1,
	ATANH			=> 1,
	DGET			=> 3,
	CREATEOBJECT	=> -2,
	VOLATILE		=> -2,
	LASTERROR		=> -2,
	CUSTOMUNDO		=> -2,
	CUSTOMREPEAT	=> -2,
	FORMULACONVERT	=> -2,
	GETLINKINFO		=> -2,
	TEXTBOX			=> -2,
	INFO			=> 1,
	GROUP			=> -2,
	GETOBJECT		=> -2,
	DB				=> -1,
	PAUSE			=> -2,
	Dummy249		=> 0,
	Dummy250		=> 0,
	RESUME			=> -2,
	FREQUENCY		=> 2,
	ADDTOOLBAR		=> -2,
	DELETETOOLBAR	=> -2,
	Dummy255		=> 0,
	RESETTOOLBAR	=> -2,
	EVALUATE		=> -2,
	GETTOOLBAR		=> -2,
	GETTOOL			=> -2,
	SPELLINGCHECK	=> -2,
	ERRORTYPE		=> 1,
	APPTITLE		=> -2,
	WINDOWTITLE		=> -2,
	SAVETOOLBAR		=> -2,
	ENABLETOOL		=> -2,
	PRESSTOOL		=> -2,
	REGISTERID		=> -2,
	GETWORKBOOK		=> -2,
	AVEDEV			=> -1,
	BETADIST		=> -1,
	GAMMALN			=> 1,
	BETAINV			=> -1,
	BINOMDIST		=> 4,
	CHIDIST			=> 2,
	CHIINV			=> 2,
	COMBIN			=> 2,
	CONFIDENCE		=> 3,
	CRITBINOM		=> 3,
	EVEN			=> 1,
	EXPONDIST		=> 3,
	FDIST			=> 3,
	FINV			=> 3,
	FISHER			=> 1,
	FISHERINV		=> 1,
	FLOOR			=> 2,
	GAMMADIST		=> 4,
	GAMMAINV		=> 3,
	CEILING			=> 2,
	HYPGEOMDIST		=> 4,
	LOGNORMDIST		=> 3,
	LOGINV			=> 3,
	NEGBINOMDIST	=> 3,
	NORMDIST		=> 4,
	NORMSDIST		=> 1,
	NORMINV			=> 3,
	NORMSINV		=> 1,
	STANDARDIZE		=> 3,
	ODD				=> 1,
	PERMUT			=> 2,
	POISSON			=> 3,
	TDIST			=> 3,
	WEIBULL			=> 4,
	SUMXMY2			=> 2,
	SUMX2MY2		=> 2,
	SUMX2PY2		=> 2,
	CHITEST			=> 2,
	CORREL			=> 2,
	COVAR			=> 2,
	FORECAST		=> 3,
	FTEST			=> 2,
	INTERCEPT		=> 2,
	PEARSON			=> 2,
	RSQ				=> 2,
	STEYX			=> 2,
	SLOPE			=> 2,
	TTEST			=> 4,
	PROB			=> -1,
	DEVSQ			=> -1,
	GEOMEAN			=> -1,
	HARMEAN			=> -1,
	SUMSQ			=> -1,
	KURT			=> -1,
	SKEW			=> -1,
	ZTEST			=> -1,
	LARGE			=> 2,
	SMALL			=> 2,
	QUARTILE		=> 2,
	PERCENTILE		=> 2,
	PERCENTRANK		=> -1,
	MODE			=> -1,
	TRIMMEAN		=> 2,
	TINV			=> 2,
	Dummy333		=> 0,
	MOVIECOMMAND	=> -2,
	GETMOVIE		=> -2,
	CONCATENATE		=> -1,
	POWER			=> 2,
	PIVOTADDDATA	=> 0,		# Number of Parameters is Unknown
	GETPIVOTTABLE	=> 0,		# Number of Parameters is Unknown
	GETPIVOTFIELD	=> 0,		# Number of Parameters is Unknown
	GETPIVOTITEM	=> 0,		# Number of Parameters is Unknown
	RADIANS			=> 1,
	DEGREES			=> 1,
	SUBTOTAL		=> -1,
	SUMIF			=> -1,
	COUNTIF			=> 2,
	COUNTBLANK		=> 1,
	SCENARIOGET		=> -2,
	OPTIONSLISTSGET	=> -2,
	ISPMT			=> 4,
	DATEDIF			=> 3,
	DATESTRING		=> 1,
	NUMBERSTRING	=> 2,
	ROMAN			=> -1,
	OPENDIALOG		=> -2,
	SAVEDIALOG		=> -2,
	VIEWGET			=> -2,
	GETPIVOTDATA	=> -1,
	HYPERLINK		=> -1,
	PHONETIC		=> 1,
	AVERAGEA		=> -1,
	MAXA			=> -1,
	MINA			=> -1,
	STDEVPA			=> -1,
	VARPA			=> -1,
	STDEVA			=> -1,
	VARA			=> -1
);
#------------------------------------------------------------------------------
# Spreadsheet::ParseExcel2->new
#------------------------------------------------------------------------------
sub new($;%) {
    my($sPkg, %hParam) =@_;

#0. Check ENDIAN(Little: Interl etc. BIG: Sparc etc)
    $BIGENDIAN = (defined $hParam{Endian})? $hParam{Endian} :
                    (unpack("H08", pack("L", 2)) eq '02000000')? 0: 1;
    my $oThis = {};
    bless $oThis, $sPkg;

#1. Set Parameter
#1.1 Get Content
    $oThis->{GetContent} = \&_subGetContent;

#1.2 Set Event Handler
    if($hParam{EventHandlers}) {
        $oThis->SetEventHandlers($hParam{EventHandlers});
    }
    else {
        $oThis->SetEventHandlers(\%ProcTbl);
    }
    if($hParam{AddHandlers}) {
        foreach my $sKey (keys(%{$hParam{AddHandlers}})) {
            $oThis->SetEventHandler($sKey, $hParam{AddHandlers}->{$sKey});
        }
    }
#Experimental
    $_CellHandler = $hParam{CellHandler} if($hParam{CellHandler});
    $_NotSetCell  = $hParam{NotSetCell};
    $_Object      = $hParam{Object};

    return $oThis;
}
#------------------------------------------------------------------------------
# Spreadsheet::ParseExcel2->SetEventHandler
#------------------------------------------------------------------------------
sub SetEventHandler($$\&) {
    my($oThis, $sKey, $oFunc) = @_;
    $oThis->{FuncTbl}->{$sKey} = $oFunc;
}
#------------------------------------------------------------------------------
# Spreadsheet::ParseExcel2->SetEventHandlers
#------------------------------------------------------------------------------
sub SetEventHandlers($$) {
    my($oThis, $rhTbl) = @_;
    $oThis->{FuncTbl} = undef;
    foreach my $sKey (keys %$rhTbl) {
        $oThis->{FuncTbl}->{$sKey} = $rhTbl->{$sKey};
    }
}
#------------------------------------------------------------------------------
# Spreadsheet::ParseExcel2->Parse
#------------------------------------------------------------------------------
sub Parse($$;$) {
    my($oThis, $sFile, $oWkFmt)=@_;
	debug("sFile=$sFile") if $DEBUG;
    my($sWk, $bLen);

#0. New $oBook
    my $oBook = Spreadsheet::ParseExcel2::Workbook->new;
    $oBook->{SheetCount} = 0;

#1.Get content
    my($sBIFF, $iLen);
    
    if(ref($sFile) eq "SCALAR") {
#1.1 Specified by Buffer
        ($sBIFF, $iLen) = $oThis->{GetContent}->($sFile);
        return undef unless($sBIFF);	
    }
#1.2 Specified by Other Things(HASH reference etc)
#    elsif(ref($sFile)) {
#        return undef;
#    }
#1.2 Specified by GLOB reference
     elsif((ref($sFile) =~ /GLOB/) or
           (ref($sFile) eq 'Fh')) { #For CGI.pm (Light FileHandle)
        binmode($sFile);
        my $sWk;
        my $sBuff='';
        while(read($sFile, $sWk, 4096)) {
            $sBuff .= $sWk;
        }                
        ($sBIFF, $iLen) = $oThis->{GetContent}->(\$sBuff);
        return undef unless($sBIFF);
     }
    elsif(ref($sFile) eq 'ARRAY') {
#1.3 Specified by File content
        $oBook->{File} = undef;
        my $sData = join('', @$sFile);
        ($sBIFF, $iLen) = $oThis->{GetContent}->(\$sData);
        return undef unless($sBIFF);
    }
    else {
#1.4 Specified by File name
        $oBook->{File} = $sFile;
        return undef unless (-e $sFile);
        ($sBIFF, $iLen) = $oThis->{GetContent}->($sFile);
        return undef unless($sBIFF);
    }

#2. Ready for format
    if ($oWkFmt) {
        $oBook->{FmtClass} = $oWkFmt;
    }
    else {
#        require Spreadsheet::ParseExcel2::FmtDefault;
        $oBook->{FmtClass} = new Spreadsheet::ParseExcel::FmtDefault;
    }

#3. Parse content
    my $lPos = 0;
    $sWk = substr($sBIFF, $lPos, 4);
    $lPos += 4;
    my $iEfFlg = 0;
    while($lPos<=$iLen) {
        my($bOp, $bLen) = unpack("v2", $sWk);

		debug(sprintf('$lPos=%5d, $bLen=%4d, $bOp=0x%4X:%s', $lPos, $bLen, $bOp, $RECORD_NAME{$bOp})) if $DEBUG;

       if($bLen) {
            $sWk = substr($sBIFF, $lPos, $bLen);
            $lPos += $bLen;
        }
#printf STDERR "%4X:%s\n", $bOp, 'UNDEFIND---:' . unpack("H*", $sWk) unless($NameTbl{$bOp});
        #Check EF, EOF
        if($bOp == 0xEF) {    #EF
            $iEfFlg = $bOp;
        }
        elsif($bOp == 0x0A) { #EOF
            undef $iEfFlg;
        }
        unless($iEfFlg) {
        #1. Formula String with No String 
            if($oBook->{_PrevPos} && (defined $oThis->{FuncTbl}->{$bOp}) &&
                ($bOp != 0x207)) {
                my $iPos = $oBook->{_PrevPos};
                $oBook->{_PrevPos} = undef;
                my($iR, $iC, $iF) = @$iPos; 
                _NewCell (
                    $oBook, $iR, $iC,
                    Kind    => 'Formula String',
                    Val     => '',
                    FormatNo=> $iF,
                    Format  => $oBook->{Format}[$iF],
                    Numeric => 0,
                    Code    => undef,
                    Book    => $oBook,
                );                         
            }
            if(defined $oThis->{FuncTbl}->{$bOp} && $bOp != $CF_RECORD_ID && $bOp != $CONDFMT_RECORD_ID) {
                $oThis->{FuncTbl}->{$bOp}->($oBook, $bOp, $bLen, $sWk);
            }
            $PREFUNC = $bOp if $bOp != 0x3C; #Not Continue 
        }

		#	Handle Conditional Formatting
        if($bOp == $CF_RECORD_ID || $bOp == $CONDFMT_RECORD_ID) {
			if (exists $oThis->{FuncTbl}->{$bOp}) {
				debug(sprintf("Found CondFmt or CF record - Calling function oThis->{FuncTbl}->{bOp}=%s with bOp=0x%02x", $oThis->{FuncTbl}->{$bOp}, $bOp)) if $VERBOSE_DEBUG;
                $oThis->{FuncTbl}->{$bOp}->($oBook, $bOp, $bLen, $sWk);
			} else {
				print "ERROR: We have a Conditional Formatting Record, but there's no subroutine to handle it\n";
			}
        }

        $sWk = substr($sBIFF, $lPos, 4) if(($lPos+4) <= $iLen);
        $lPos += 4;
        #Abort Parse
        if(defined $oBook->{_ParseAbort}) {
            return $oBook;
        }
    }

#4.return $oBook
    return $oBook;
}
#------------------------------------------------------------------------------
# _subGetContent (for Spreadsheet::ParseExcel2)
#------------------------------------------------------------------------------
sub _subGetContent($)
{
        
    my($sFile)=@_;
    
    # warn qq{_subGetContent called; sFile:}, ref $sFile;
    
    my $oOl = OLE::Storage_Lite->new($sFile);
    return (undef, undef) unless($oOl);
    my @aRes = $oOl->getPpsSearch(
            [OLE::Storage_Lite::Asc2Ucs('Book'), 
             OLE::Storage_Lite::Asc2Ucs('Workbook')], 1, 1);
    return (undef, undef) if($#aRes < 0);
#Hack from Herbert
    unless($aRes[0]->{Data}) {
        #Same as OLE::Storage_Lite
        my $oIo;
        #1. $sFile is Ref of scalar
        if(ref($sFile) eq 'SCALAR') {
            $oIo = new IO::Scalar;
            $oIo->open($sFile);
        }
        #2. $sFile is a IO::Handle object
        elsif(UNIVERSAL::isa($sFile, 'IO::Handle')) {
            $oIo = $sFile;
            binmode($oIo);
        }
        #3. $sFile is a simple filename string
        elsif(!ref($sFile)) {
            $oIo = new IO::File;
            $oIo->open("<$sFile") || return undef;
            binmode($oIo);
        }
        my $sWk;
        my $sBuff ='';

        while($oIo->read($sWk, 4096)) { #4_096 has no special meanings
            $sBuff .= $sWk;
        }
        $oIo->close();
        #Not Excel file (simple method)
        return (undef, undef) if substr($sBuff, 0, 1) ne "\x09";
        return ($sBuff, length($sBuff));
    }
    else {
        return ($aRes[0]->{Data}, length($aRes[0]->{Data}));
    }
}
#------------------------------------------------------------------------------
# _subBOF (for Spreadsheet::ParseExcel2) Developers' Kit : P303
#------------------------------------------------------------------------------
sub _subBOF($$$$){
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my($iVer, $iDt) = unpack("v2", $sWk);

    #Workbook Global
    if($iDt==0x0005) {
        $oBook->{Version} = unpack("v", $sWk);
        $oBook->{BIFFVersion} = 
                ($oBook->{Version}==verExcel95)? verBIFF5:verBIFF8;
        $oBook->{_CurSheet} = undef;
        $oBook->{_CurSheet_} = -1; 
    }
    #Worksheeet or Dialogsheet
    elsif($iDt != 0x0020) {  #if($iDt == 0x0010) {
        if(defined $oBook->{_CurSheet_}) {
            $oBook->{_CurSheet} = $oBook->{_CurSheet_} + 1;
            $oBook->{_CurSheet_}++; 

            ($oBook->{Worksheet}[$oBook->{_CurSheet}]->{SheetVersion},
             $oBook->{Worksheet}[$oBook->{_CurSheet}]->{SheetType},) 
                    = unpack("v2", $sWk) if(length($sWk) > 4);
        }
        else {
            $oBook->{BIFFVersion} = int($bOp / 0x100);
            if (($oBook->{BIFFVersion} == verBIFF2) ||
                ($oBook->{BIFFVersion} == verBIFF3) ||
                ($oBook->{BIFFVersion} == verBIFF4)) {
                $oBook->{Version} = $oBook->{BIFFVersion};
                $oBook->{_CurSheet} = 0;
                $oBook->{Worksheet}[$oBook->{SheetCount}] =
                    new Spreadsheet::ParseExcel2::Worksheet(
                             _Name => '',
                              Name => '',
                             _Book => $oBook,
                            _SheetNo => $oBook->{SheetCount},
                        );
                $oBook->{SheetCount}++;
            }
        }
    }
    else {
        ($oBook->{_CurSheet_}, $oBook->{_CurSheet}) =
            (((defined $oBook->{_CurSheet})? $oBook->{_CurSheet}: -1), 
                undef);
    }
}
#------------------------------------------------------------------------------
# _subBlank (for Spreadsheet::ParseExcel2) DK:P303
#------------------------------------------------------------------------------
sub _subBlank($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my ($iR, $iC, $iF) = unpack("v3", $sWk);
    _NewCell(
            $oBook, $iR, $iC,
            Kind    => 'BLANK',
            Val     => '',
            FormatNo=> $iF,
            Format  => $oBook->{Format}[$iF],
            Numeric => 0,
            Code    => undef,
            Book    => $oBook,
        );
#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iC, $iC);
}
#------------------------------------------------------------------------------
# _subInteger (for Spreadsheet::ParseExcel2) Not in DK
#------------------------------------------------------------------------------
sub _subInteger($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my($iR, $iC, $iF, $sTxt, $sDum);

    ($iR, $iC, $iF, $sDum, $sTxt) = unpack("v3cv", $sWk);
    _NewCell (  
            $oBook, $iR, $iC,
                Kind    => 'INT',
                Val     => $sTxt,
                FormatNo=> $iF,
                Format  => $oBook->{Format}[$iF],
                Numeric => 0,
                Code    => undef,
                Book    => $oBook,
            );
#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iC, $iC);
}
#------------------------------------------------------------------------------
# _subNumber (for Spreadsheet::ParseExcel2)  : DK: P354
#------------------------------------------------------------------------------
sub _subNumber($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;

    my ($iR, $iC, $iF) = unpack("v3", $sWk);
    my $dVal = _convDval(substr($sWk, 6, 8));
    _NewCell (
                $oBook, $iR, $iC,
                Kind    => 'Number',
                Val     => $dVal,
                FormatNo=> $iF,
                Format  => $oBook->{Format}[$iF],
                Numeric => 1,
                Code    => undef,
                Book    => $oBook,
            );
#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iC, $iC);
}
#------------------------------------------------------------------------------
# _convDval (for Spreadsheet::ParseExcel2)
#------------------------------------------------------------------------------
sub _convDval($) {
    my($sWk)=@_;
    return  unpack("d", ($BIGENDIAN)? 
                    pack("c8", reverse(unpack("c8", $sWk))) : $sWk);
}
#------------------------------------------------------------------------------
# _subRString (for Spreadsheet::ParseExcel2) DK:P405
#------------------------------------------------------------------------------
sub _subRString($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my($iR, $iC, $iF, $iL, $sTxt);
    ($iR, $iC, $iF, $iL) = unpack("v4", $sWk);
    $sTxt = substr($sWk, 8, $iL);

    #Has STRUN
    if(length($sWk) > (8+$iL)) {
        _NewCell (
            $oBook, $iR, $iC,
            Kind    => 'RString',
            Val     => $sTxt,
            FormatNo=> $iF,
            Format  => $oBook->{Format}[$iF],
            Numeric => 0,
            Code    => '_native_', #undef,
            Book    => $oBook,
            Rich    => substr($sWk, (8+$iL)+1),
        );
    }
    else {
        _NewCell (
            $oBook, $iR, $iC,
            Kind    => 'RString',
            Val     => $sTxt,
            FormatNo=> $iF,
            Format  => $oBook->{Format}[$iF],
            Numeric => 0,
            Code    => '_native_',
            Book    => $oBook,
        );
    }
#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iC, $iC);
}
#------------------------------------------------------------------------------
# _subBoolErr (for Spreadsheet::ParseExcel2) DK:P306
#------------------------------------------------------------------------------
sub _subBoolErr($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my ($iR, $iC, $iF) = unpack("v3", $sWk);
    my ($iVal, $iFlg) = unpack("cc", substr($sWk, 6, 2));
    my $sTxt = DecodeBoolErr($iVal, $iFlg);

    _NewCell (
            $oBook, $iR, $iC,
            Kind    => 'BoolError',
            Val     => $sTxt,
            FormatNo=> $iF,
            Format  => $oBook->{Format}[$iF],
            Numeric => 0,
            Code    => undef,
            Book    => $oBook,
        );
#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iC, $iC);
}
#------------------------------------------------------------------------------
# _subRK (for Spreadsheet::ParseExcel2)  DK:P401
#------------------------------------------------------------------------------
sub _subRK($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my ($iR, $iC) = unpack("v3", $sWk);

    my($iF, $sTxt)= _UnpackRKRec(substr($sWk, 4, 6));
    _NewCell (
            $oBook, $iR, $iC,
            Kind    => 'RK',
            Val     => $sTxt,
            FormatNo=> $iF,
            Format  => $oBook->{Format}[$iF],
            Numeric => 1,
            Code    => undef,
            Book    => $oBook,
        );
#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iC, $iC);
}
#------------------------------------------------------------------------------
# _subArray (for Spreadsheet::ParseExcel2)   DK:P297
#------------------------------------------------------------------------------
sub _subArray($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my ($iBR, $iER, $iBC, $iEC) = unpack("v2c2", $sWk);
    
}
#------------------------------------------------------------------------------
# _subFormula (for Spreadsheet::ParseExcel2) DK:P336
#------------------------------------------------------------------------------
sub _subFormula($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my($iR, $iC, $iF) = unpack("v3", $sWk);

    my $dVal	= _convDval(substr($sWk, 6, 8));
    my($iKind)	= unpack("c", substr($sWk, 6, 1));
    my($iVal)	= unpack("c", substr($sWk, 8, 1));
    my ($iFlg)	= unpack("v", substr($sWk, 12,2));
	my($option_flags) = unpack("v", substr($sWk,14,2));

	my($shared_formula) = ($option_flags & 0x08) > 0;
	
	debug(sprintf("oBook->{_CurSheet}=%d, bOp=0x%02x, bLen=%d, iR=%d, iC=%d, iF=%d, dVal=%f, iKind=%d, iVal=%d, iFlg=%d, option_flags=%d, shared_formula=%d", $oBook->{_CurSheet}, $bOp, $bLen, $iR, $iC, $iF, $dVal, $iKind, $iVal, $iFlg, $option_flags, $shared_formula)) if $VERBOSE_DEBUG;
	my($token_string);
	my(%shared_formula) = undef;
	if ($shared_formula) {
		if ($oBook->{shared_formula_ptr}) {
			%shared_formula = %{$oBook->{shared_formula_ptr}};
			$token_string = $shared_formula{token_string};
			debug(sprintf("Found a shared formula, shared_formula{first_row}=%d, shared_formula{last_row}=%d, shared_formula{first_col}=%d, shared_formula{last_col}=%d, shared_formula{token_string}=0x%s", $shared_formula{first_row}, $shared_formula{last_row}, $shared_formula{first_col}, $shared_formula{last_col}, unpack("H*", $shared_formula{token_string}))) if $VERBOSE_DEBUG;
		} else {
			#
			#	Okay, so we've found a formula that's shared,
			#	but no shared formula record has been encountered yet,
			#	so we'll have to wait for the shared formula record
			#	before we can emit this formula.
			#
			#	Consequently, we need to save the formula's state, so that
			#	we can emit it when we parse the shared formula record.
			#
			my(%formula_state) = (
				iR			=> $iR,
				iC			=> $iC,
				iF			=> $iF,
				dVal		=> $dVal,
				iKind		=> $iKind,
				iVal		=> $iVal,
				iFlg		=> $iFlg,
				option_flags=> $option_flags,
				iKind		=> $iKind,
				iVal		=> $iVal,
			);
			$oBook->{formula_state_ptr} = \%formula_state;
			return;
		}
	} else {
		my($formula_data) = substr($sWk, 20, ($bLen - 20));
		$token_string = substr($formula_data, 2);
	}
	emit_formula($oBook, $iR, $iC, $iF, $dVal, $iKind, $iVal, $iFlg, $token_string);
}
#------------------------------------------------------------------------------
# emit_formula
#------------------------------------------------------------------------------
sub emit_formula {
	my($oBook, $iR, $iC, $iF, $dVal, $iKind, $iVal, $iFlg, $token_string) = @_;
	my($formula_string) = formula_to_string($iR, $iC, $token_string);
	$oBook->{Formula} = $formula_string;
	debug(sprintf("iR=%d, iC=%d, iF=%d, dVal=%f, iKind=%d, iVal=%d, iFlg=%d, token_string=0x%s, oBook->{Formula}=%s", $iR, $iC, $iF, $dVal, $iKind, $iVal, $iFlg, unpack("H*", $token_string), $oBook->{Formula})) if $VERBOSE_DEBUG;
	#
	#	Formula Result type is String, Boolean, Error, or Empty
	#		In other words, it's anything _but_ a Double
	#		In other other words, it's a non-numeric formula result
	#
    if ($iFlg == 0xFFFF) {
        if (($iKind==1) or ($iKind==2)) {	# Formula Result is Boolean or Error
            my $sTxt = ($iKind == 1) ? DecodeBoolErr($iVal, 0) : DecodeBoolErr($iVal, 1);
            _NewCell (
                    $oBook, $iR, $iC,
                    Kind    => 'Formula Bool',
                    Val     => $sTxt,
                    FormatNo=> $iF,
                    Format  => $oBook->{Format}[$iF],
                    Numeric => 0,
                    Code    => undef,
                    Book    => $oBook,
                );
        }
        else {									# Formula Result is a String
            $oBook->{_PrevPos} = [$iR, $iC, $iF, ];
			debug("Formula Result is a String: iR=$iR, iC=$iC, iF=$iF") if $VERBOSE_DEBUG;
        }
    } else {									# Formula Result is a Double
        _NewCell (
                $oBook, $iR, $iC,
                Kind    => 'Formula Number',
                Val     => $dVal,
                FormatNo=> $iF,
                Format  => $oBook->{Format}[$iF],
                Numeric => 1,
                Code    => undef,
                Book    => $oBook,
            );
    }

	#2. MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iC, $iC);
}
#------------------------------------------------------------------------------
# _subSharedFormula
#------------------------------------------------------------------------------
sub _subSharedFormula($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;

	my(%shared_formula);
	my($token_string_len);
	($shared_formula{first_row}, $shared_formula{last_row}, $shared_formula{first_col}, $shared_formula{last_col}, $token_string_len) = unpack("v2 C2 x2 v", $sWk);
	$shared_formula{token_string} = substr($sWk, 10, $token_string_len);
	$oBook->{shared_formula_ptr} = \%shared_formula;

	debug(sprintf("oBook->{_CurSheet}=%d, bOp=0x%02X, bLen=%d, shared_formula{first_row}=%d, shared_formula{last_row}=%d, shared_formula{first_col}=%d, shared_formula{last_col}=%d, token_string_len=%d, shared_formula{token_string}=0x%s", $oBook->{_CurSheet}, $bOp, $bLen, $shared_formula{first_row}, $shared_formula{last_row}, $shared_formula{first_col}, $shared_formula{last_col}, $token_string_len, unpack("H*", $shared_formula{token_string}), hash_to_string("oBook->{shared_formula}", $oBook->{shared_formula_ptr}))) if $VERBOSE_DEBUG;

	my(%formula_state) = %{$oBook->{formula_state_ptr}};
	emit_formula($oBook, $formula_state{iR}, $formula_state{iC}, $formula_state{iF}, $formula_state{dVal}, $formula_state{iKind}, $formula_state{iVal}, $formula_state{iFlg}, $shared_formula{token_string});
}
#------------------------------------------------------------------------------
# _subCondFmt
#------------------------------------------------------------------------------
sub _subCondFmt($$$$)
{
    my ($oBook, $bOp, $bLen, $sWk) = @_;

	debug(sprintf('sWk=0x%s', unpack("H*", $sWk))) if $COND_FMT_DEBUG;

	my $condFmt = Spreadsheet::ParseExcel2::CondFmt->new($sWk);

	$oBook->{cf_first_row} = $condFmt->{all_first_row};
	$oBook->{cf_first_col} = $condFmt->{all_first_col};

#JJT
	$oBook->{Worksheet}[$oBook->{_CurSheet}]->{CondFmt} = () unless defined($oBook->{Worksheet}[$oBook->{_CurSheet}]->{CondFmt});
	push @{$oBook->{Worksheet}[$oBook->{_CurSheet}]->{CondFmt}}, $condFmt;
}
#------------------------------------------------------------------------------
# _subCF
#------------------------------------------------------------------------------
sub _subCF($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;

	my($type_index, $operator_index, $first_formula_len, $second_formula_len, $option_flags) = unpack("C C v v V", $sWk);

	my($type_string)	= $CF_TYPE_STRINGS[$type_index];
	my($operator_string)= $CF_OPERATOR_STRINGS[$operator_index];

	#	Add this CF to the current CondFmt row/object
	my @condFmts = @{$oBook->{Worksheet}[$oBook->{_CurSheet}]->{CondFmt}};
	$condFmts[-1]->add_cf($sWk);

	#	Border Modifications
	my($left_border_style_and_color_modified);
	if (($option_flags & $CF_LEFT_BORDER_STYLE_AND_COLOR_MODIFIED) == 0) {
		$left_border_style_and_color_modified = 1;
		#debug("Left Border Style and Color Modified") if $COND_FMT_DEBUG;
	}
	my($right_border_style_and_color_modified);
	if (($option_flags & $CF_RIGHT_BORDER_STYLE_AND_COLOR_MODIFIED) == 0) {
		$right_border_style_and_color_modified = 1;
		#debug("Right Border Style and Color Modified") if $COND_FMT_DEBUG;
	}
	my($top_border_style_and_color_modified);
	if (($option_flags & $CF_TOP_BORDER_STYLE_AND_COLOR_MODIFIED) == 0) {
		$top_border_style_and_color_modified = 1;
		#debug("Top Border Style and Color Modified") if $COND_FMT_DEBUG;
	}
	my($bottom_border_style_and_color_modified);
	if (($option_flags & $CF_BOTTOM_BORDER_STYLE_AND_COLOR_MODIFIED) == 0) {
		$bottom_border_style_and_color_modified = 1;
		#debug("Bottom Border Style and Color Modified") if $COND_FMT_DEBUG;
	}

	#	Pattern Modifications
	my($pattern_style_modified);
	if (($option_flags & $CF_PATTERN_STYLE_MODIFIED) == 0) {
		$pattern_style_modified = 1;
		#debug("Pattern Style Modified") if $COND_FMT_DEBUG;
	}
	my($pattern_color_modified);
	if (($option_flags & $CF_PATTERN_COLOR_MODIFIED) == 0) {
		$pattern_color_modified = 1;
		#debug("Pattern Color Modified") if $COND_FMT_DEBUG;
	}
	my($pattern_background_modified);
	if (($option_flags & $CF_PATTERN_BACKGROUND_MODIFIED) == 0) {
		$pattern_background_modified = 1;
		#debug("Pattern Background Modified") if $COND_FMT_DEBUG;
	}

	#	Formatting Blocks
	my($offset) = 12;
	my($record_contains_font_formatting_block);
	if (($option_flags & $CF_RECORD_CONTAINS_FONT_FORMATTING_BLOCK) > 0) {
		$record_contains_font_formatting_block = 1;
		my($font_formatting_block) = substr($sWk, $offset, $CF_FONT_FORMATTING_BLOCK_SIZE);
		$offset += $CF_FONT_FORMATTING_BLOCK_SIZE;
		#debug(sprintf("Font Formatting Block: 0x%s", unpack("H*", $font_formatting_block))) if $COND_FMT_DEBUG;
	}
	my($record_contains_border_formatting_block);
	if (($option_flags & $CF_RECORD_CONTAINS_BORDER_FORMATTING_BLOCK) > 0) {
		$record_contains_border_formatting_block = 1;
		my($border_formatting_block) = substr($sWk, $offset, $CF_BORDER_FORMATTING_BLOCK_SIZE);
		$offset += $CF_BORDER_FORMATTING_BLOCK_SIZE;
		#debug(sprintf("Border Formatting Block: 0x%s", unpack("H*", $border_formatting_block))) if $COND_FMT_DEBUG;
	}
	my($record_contains_pattern_formatting_block);
	if (($option_flags & $CF_RECORD_CONTAINS_PATTERN_FORMATTING_BLOCK) > 0) {
		$record_contains_pattern_formatting_block = 1;
		my($pattern_formatting_block) = substr($sWk, $offset, $CF_PATTERN_FORMATTING_BLOCK_SIZE);
		$offset += $CF_PATTERN_FORMATTING_BLOCK_SIZE;
		#debug(sprintf("Pattern Formatting Block: 0x%s", unpack("H*", $pattern_formatting_block))) if $COND_FMT_DEBUG;
	}

	#	Formula Data
	if ($first_formula_len > 0) {
		my($first_formula_data) = substr($sWk, $offset, $first_formula_len);
		$offset += $first_formula_len;
		my($first_formula) = formula_to_string($oBook->{cf_first_row}, $oBook->{cf_first_col}, $first_formula_data);
		#debug(sprintf("first_formula_len=%d, first_formula_data=0x%s, first_formula=%s", $first_formula_len, unpack("H*", $first_formula_data), $first_formula)) if $COND_FMT_DEBUG;
		#debug("Conditional is \"$operator_string$first_formula\"") if $type_string eq 'Compare to Cell Value' && $COND_FMT_DEBUG;
	}
	if ($second_formula_len > 0) {
		my($second_formula_data) = substr($sWk, $offset, $second_formula_len);
		$offset += $second_formula_len;
		my($second_formula) = formula_to_string(-1, -1, $second_formula_data);
		#debug(sprintf("second_formula_len=%d, second_formula_data=0x%s, second_formula=%s", $second_formula_len, unpack("H*", $second_formula_data), $second_formula)) if $COND_FMT_DEBUG;
	}
}
#------------------------------------------------------------------------------
# formula_to_string
#------------------------------------------------------------------------------
sub formula_to_string {
	my ($iR, $iC, $buffer) = @_;
	my ($debug_string);
	my ($rpn_string);
	my ($return_string);

	debug(sprintf("buffer=0x%s", unpack("H*", $buffer))) if $VERBOSE_DEBUG;

	return "#NAME" if (!defined($buffer) || length($buffer) < 1);
	#
	#	Parse the formula string into an array of PTGs
	#
	debug("The PTGs in this buffer are as follows:") if $VERBOSE_DEBUG;
	my (@ptg_ptrs) = parse_tokens($iR, $iC, $buffer);
	foreach my $i (0 .. $#ptg_ptrs) {
		my ($ptg_ptr) = $ptg_ptrs[$i];
		print_hash("formula_to_string: ptg", $ptg_ptr) if $VERBOSE_DEBUG;
		$rpn_string .= $$ptg_ptr{string};
		$rpn_string .= "," if $i != $#ptg_ptrs;
		$debug_string .= $$ptg_ptr{debug};
		$debug_string .= "," if $i != $#ptg_ptrs;
	}
	debug("debug_string=$debug_string") if $VERBOSE_DEBUG;
	debug("rpn_string=$rpn_string") if $VERBOSE_DEBUG;
	#
	#	Convert the RPN of PTGs into a human readable formula string
	#
	my @stack;
	push @stack, ${$ptg_ptrs[0]}{string};
	for my $i (1..$#ptg_ptrs) {
		my ($ptg_ptr) = $ptg_ptrs[$i];
		my (%ptg) = %$ptg_ptr;
		#
		#	Process the RPN stack of PTGs into an infix formula string
		#
		if ($ptg{type} eq 'operand') {
			push @stack, $ptg{string};
		} elsif ($ptg{type} eq 'control') {
			push @stack, generate_infix_string(\%ptg, \@stack);
		} elsif ($ptg{type} eq 'operator') {
			push @stack, generate_infix_string(\%ptg, \@stack);
		} else {
			print "FATAL ERROR: Unknown type of '$ptg{type}' in the following PTG:\n";
			print_hash("ptg", \%ptg);
		}
	}
	$return_string = pop @stack;
	debug("return_string=$return_string") if $VERBOSE_DEBUG;

	return ($return_string);
}
#------------------------------------------------------------------------------
# generate_infix_string
#------------------------------------------------------------------------------
sub generate_infix_string {
	my ($ptg_ptr, $stack_ptr) = @_;
	my (%ptg) = %$ptg_ptr;

	#	If no operands, then just return the string
	return $ptg{string} if $ptg{num_operands} < 1;

	if (!exists $ptg{to_infix}) {
		print "FATAL ERROR: No to_infix function for a PTG with operands\n";
		print_hash("ptg", \%ptg);
		return $ptg{string};
	}

	my $num_operands = $ptg{num_operands};
	my @operands;
	for my $j (1..$num_operands) {
		$operands[$j-1] = pop @$stack_ptr;
	}
	@operands = reverse @operands;
	my $func_ptr = $ptg{to_infix};
	my $infix_string = $func_ptr->(\%ptg, @operands);
	debug("ptg{id}=$ptg{id}, ptg{string}=$ptg{string}, operands=@operands, infix_string=$infix_string") if $VERBOSE_DEBUG;

	return $infix_string;
}
#------------------------------------------------------------------------------
# parse_tokens (for Spreadsheet::ParseExcel2)
#------------------------------------------------------------------------------
sub parse_tokens {
	my ($iR, $iC, $buffer) = @_;
	my ($position) = 0;
	my (@output_stack);
	debug(sprintf("parse_tokens: buffer=0x%s", unpack("H*", $buffer))) if $VERBOSE_DEBUG;

	while ($position < length($buffer)) {
		my ($ptg_ptr) = parse_token($iR, $iC, substr($buffer, $position));
		my (%ptg) = %$ptg_ptr;
		if (exists($ptg{size})) {
			$position += $ptg{size};
		} else {
			debug("This ptg hash doesn't have a {size} key, so we'll use size=1.") if $VERBOSE_DEBUG;
			print_hash("parse_tokens: ptg", \%ptg) if $VERBOSE_DEBUG;
			$position++;
		}

		# Push it on the stack, unless it's a tAttr token, unless it's tAttrSum
		if ($ptg{id} == $ATTR{id} && $ptg{attr_type} ne 'Sum') {
			debug("We're not pushing this token onto the stack: $ptg{debug}") if $VERBOSE_DEBUG;
				next;
		}
		push(@output_stack, $ptg_ptr);
	}

	return(@output_stack);
}
#------------------------------------------------------------------------------
# parse_token
#------------------------------------------------------------------------------
sub parse_token {
	my ($iR, $iC, $buffer) = @_;
	my ($id) = unpack("C", $buffer);

	if (!exists $PTG{$id}) {
		printf "FATAL ERROR: Unknown PTG with id of 0x%02x in buffer %s\n", $id, unpack("H*", $buffer);
		return \%UNKNOWN;
	}

	my ($ptg_ptr) = $PTG{$id};
	my (%ptg) = %{$ptg_ptr};
	debug(sprintf("id=0x%02x, buffer=0x%s, %s", $id, unpack("H*", $buffer), hash_to_string("ptg", $ptg_ptr))) if $VERBOSE_DEBUG;
	if (exists $ptg{parser}) {
		my $func_ptr = $ptg{parser};
		$ptg_ptr = $func_ptr->($iR, $iC, $id, $ptg_ptr, substr($buffer, 1));
		%ptg = %{$ptg_ptr};
		print_hash("parse_token: ptg", $ptg_ptr) if $VERBOSE_DEBUG;
	} else {
		print "parse_token: There's no parser for token id=$id\n" if $VERBOSE_DEBUG;
	}

	return $ptg_ptr;
}
#------------------------------------------------------------------------------
# parse_bool
#------------------------------------------------------------------------------
sub parse_bool {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	my ($boolean_value) = unpack("C", $buffer);
	my ($string_value) = ($boolean_value == 1) ? "TRUE" : "FALSE";

	$ptg{string} = $string_value;
	$ptg{debug} = "BOOL:$string_value";
	parse_debug("parse_bool", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_int
#------------------------------------------------------------------------------
sub parse_int {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	my ($int_value) = unpack("C", $buffer);

	$ptg{string} = $int_value;
	$ptg{debug} = "INT:$int_value";
	parse_debug("parse_int", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_area
#------------------------------------------------------------------------------
sub parse_area {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	($ptg{first_row}, $ptg{last_row}, $ptg{first_col}, $ptg{last_col}) = unpack("v4", $buffer);

	$ptg{first_cell} = map_row_and_col_number_to_cell_reference($ptg{first_row}, $ptg{first_col});
	$ptg{last_cell}  = map_row_and_col_number_to_cell_reference($ptg{last_row},  $ptg{last_col});

	$ptg{string} = "$ptg{first_cell}:$ptg{last_cell}";
	$ptg{debug} = "AREA" . map_id_to_suffix($id) . ":first_row=$ptg{first_row}:last_row=$ptg{last_row}:first_col=$ptg{first_col}:last_col=$ptg{last_col}:first_cell=$ptg{first_cell}:last_cell=$ptg{last_cell}";
	parse_debug("parse_area", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_area_n
#------------------------------------------------------------------------------
sub parse_area_n {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	my ($first_row, $last_row, $first_col, $last_col) = unpack("v4", $buffer);
	my ($first_row_ref_is_relative, $first_col_ref_is_relative);
	($first_row, $first_col, $first_row_ref_is_relative, $first_col_ref_is_relative) = parse_cell_numbers($first_row, $first_col);
	my ($last_row_ref_is_relative, $last_col_ref_is_relative);
	($last_row, $last_col, $last_row_ref_is_relative, $last_col_ref_is_relative) = parse_cell_numbers($last_row, $last_col);

	my $first_row_offset = map_signed_2byte_to_unsigned($first_row);
	my $first_col_offset = map_signed_2byte_to_unsigned($first_col);
	my  $last_row_offset = map_signed_2byte_to_unsigned( $last_row);
	my  $last_col_offset = map_signed_2byte_to_unsigned( $last_col);

	$ptg{first_row} = $iR + $first_row_offset;
	$ptg{first_col} = $iC + $first_col_offset;
	$ptg{last_row}  = $iR + $ last_row_offset;
	$ptg{last_col}  = $iC + $ last_col_offset;

	$ptg{first_cell} = map_row_col_flags_to_cell_reference($ptg{first_row}, $ptg{first_col}, $first_row_ref_is_relative, $first_col_ref_is_relative);
	$ptg{last_cell}  = map_row_col_flags_to_cell_reference($ptg{last_row},  $ptg{last_col},   $last_row_ref_is_relative,  $last_col_ref_is_relative);

	$ptg{string} = "$ptg{first_cell}:$ptg{last_cell}";
	$ptg{debug} = "AREA_N" . map_id_to_suffix($id) . ":first_row=$ptg{first_row}:last_row=$ptg{last_row}:first_col=$ptg{first_col}:last_col=$ptg{last_col}:first_cell=$ptg{first_cell}:last_cell=$ptg{last_cell}";

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_mem_err
#------------------------------------------------------------------------------
sub parse_mem_err {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	($ptg{reserved}, $ptg{subex_len}) = unpack("V v", $buffer);

	$ptg{string} = "$ptg{reserved}:$ptg{subex_len}";
	$ptg{debug} = "MEM_ERR" . map_id_to_suffix($id) . ":reserved=$ptg{reserved}:subex_len=$ptg{subex_len}";
	parse_debug("parse_mem_err", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_attr
#------------------------------------------------------------------------------
sub parse_attr {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	my $options = unpack("C", $buffer);

	my $volatile_attribute		= ($options == $VOLATILE_ATTRIBUTE);
	my $if_attribute			= ($options == $IF_ATTRIBUTE);
	my $choose_attribute		= ($options == $CHOOSE_ATTRIBUTE);
	my $skip_attribute			= ($options == $SKIP_ATTRIBUTE);
	my $sum_attribute			= ($options == $SUM_ATTRIBUTE);
	my $assign_attribute		= ($options == $ASSIGN_ATTRIBUTE);
	my $space_attribute			= ($options == $SPACE_ATTRIBUTE);
	my $space_volatile_attribute= ($options == $SPACE_VOLATILE_ATTRIBUTE);

	$ptg{debug} = "";
	if ($volatile_attribute) {
		$ptg{attr_type} = "Volatile";
	} elsif ($if_attribute) {
		$ptg{attr_type} = "If";
	} elsif ($choose_attribute) {
		$ptg{attr_type} = "Choose";
		my $offset = 1;
		my $number_of_choices = unpack("v", substr($buffer,$offset));
		$offset += 2;
		my @jump_offsets = unpack("C$number_of_choices", substr($buffer, $offset));
		$offset += (2 * $number_of_choices);
		my $distance_to_choose_token = unpack("v", substr($buffer, $offset));
		$offset += 2;
		$ptg{size} = 1 + $offset;
		$ptg{debug} = ",number_of_choices=$number_of_choices,jump_offsets=@jump_offsets,distance_to_choose_token=$distance_to_choose_token";
	} elsif ($skip_attribute) {
		$ptg{attr_type} = "Skip";
	} elsif ($sum_attribute) {
		$ptg{attr_type} = "Sum";
	} elsif ($assign_attribute) {
		$ptg{attr_type} = "Assign";
	} elsif ($space_attribute) {
		$ptg{attr_type} = "Space";
	} elsif ($space_volatile_attribute) {
		$ptg{attr_type} = "Space-Attribute";
	} else {
		$ptg{attr_type} = "<UNKNOWN>";
	}

	$ptg{string} = "";
	$ptg{debug} = "ptg{attr_type}=$ptg{attr_type}" . $ptg{debug};
	debug(sprintf("buffer=0x%s, ptg{debug}=%s", unpack("H*", $buffer), $ptg{debug})) if $VERBOSE_DEBUG;
	parse_debug("parse_attr", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_reference
#------------------------------------------------------------------------------
sub parse_reference {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	($ptg{row}, $ptg{col}) = unpack("v2", $buffer);
	$ptg{cell} = map_row_and_col_number_to_cell_reference($ptg{row}, $ptg{col});

	$ptg{string} = $ptg{cell};
	$ptg{debug} = "REFERENCE" . map_id_to_suffix($id) . ":row=$ptg{row},col=$ptg{col},cell=$ptg{cell}";
	parse_debug("parse_reference", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_reference_n
#------------------------------------------------------------------------------
sub parse_reference_n {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	my ($original_row, $original_col, $row_ref_is_relative, $col_ref_is_relative)= parse_cell_numbers(unpack("v2", $buffer));
	my ($row_offset) = map_signed_2byte_to_unsigned($original_row);
	my ($col_offset) = map_signed_2byte_to_unsigned($original_col);

	$ptg{row} = $iR + $row_offset;
	$ptg{col} = $iC + $col_offset;

	$ptg{cell} = map_row_col_flags_to_cell_reference($ptg{row}, $ptg{col}, $row_ref_is_relative, $col_ref_is_relative);

	$ptg{string} = $ptg{cell};
	$ptg{debug} = "REFERENCE_N" . map_id_to_suffix($id) . ":row=$ptg{row}:col=$ptg{col}:cell=$ptg{cell}";

	debug("iR=$iR, iC=$iC, original_row=$original_row, original_col=$original_col, row_ref_is_relative=$row_ref_is_relative, col_ref_is_relative=$col_ref_is_relative,   row_offset=$row_offset, col_offset=$col_offset, ptg{row}=$ptg{row}, prg{col}=$ptg{col}, ptg{debug}=$ptg{debug}, ptg{string}=$ptg{string}") if $VERBOSE_DEBUG;
	parse_debug("parse_reference_n", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# unpack_signed_2byte_little_endian
#------------------------------------------------------------------------------
sub unpack_signed_2byte_little_endian {
	my ($buffer, $index) = @_;

	my ($number) = unpack("v", substr($buffer, $index, 2));
	return map_signed_2byte_to_unsigned($number);
}
#------------------------------------------------------------------------------
# map_signed_2byte_to_unsigned
#------------------------------------------------------------------------------
sub map_signed_2byte_to_unsigned {
	my ($number) = @_;

	my ($negative) = ($number & 0x8000) > 0;

	$number &= 0x7FFF;
	$number = -(0x8000 - $number) if $negative;

	return $number;
}
#------------------------------------------------------------------------------
# map_row_and_col_number_to_cell_reference
#------------------------------------------------------------------------------
sub map_row_and_col_number_to_cell_reference($$) {
	my ($row, $col) = @_;
	my ($row_relative, $col_relative);

	($row, $col, $row_relative, $col_relative) = parse_cell_numbers($row, $col);
	return map_row_col_flags_to_cell_reference($row, $col, $row_relative, $col_relative);
}
#------------------------------------------------------------------------------
# map_row_col_flags_to_cell_reference
#------------------------------------------------------------------------------
sub map_row_col_flags_to_cell_reference($$$$) {
	my ($row, $col, $row_relative, $col_relative) = @_;

	my $string = ($col_relative ? '' : '$') . convert_column_num_to_alpha_string($col) . ($row_relative ? '' : '$') . ($row + 1);

	return $string;
}
#------------------------------------------------------------------------------
#
#	Take a 0-based base-10 column number and return an ALPHA-26 string
#
# convert_column_num_to_alpha_string
#------------------------------------------------------------------------------
sub convert_column_num_to_alpha_string($) {
	my ($col) = @_;
	print "convert_column_num_to_alpha_string($col)\n" if $VERBOSE_DEBUG;

	my ($modulo) = $col % 26;
	my ($divide) = int($col / 26);

	my ($small) = chr(ord('A') + $modulo);
	my ($big) = chr(ord('A') + $divide - 1);

	return ($divide == 0 ? $small : "$big$small");
}
#------------------------------------------------------------------------------
# parse_cell_numbers
#------------------------------------------------------------------------------
sub parse_cell_numbers {
	my ($row, $col) = @_;

	my ($row_relative) = ($col & $ROW_RELATIVE_MASK) > 0;
	my ($col_relative) = ($col & $COL_RELATIVE_MASK) > 0;
	$col = $col & 0x3FFF;
	print "parse_cell_numbers: row=$row, col=$col, row_relative=$row_relative, col_relative=$col_relative\n" if $VERBOSE_DEBUG;

	return ($row, $col, $row_relative, $col_relative);
}
#------------------------------------------------------------------------------
# parse_mem_func
#------------------------------------------------------------------------------
sub parse_mem_func {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	$ptg{subex_ref_len}	= unpack("v", $buffer);

	$ptg{string} = "$ptg{subex_ref_len}";
	$ptg{debug} = "MEM_FUNC:subex_ref_len=$ptg{subex_ref_len}";
	parse_debug("parse_mem_func", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_parenthesis
#------------------------------------------------------------------------------
sub parse_parenthesis {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	$ptg{string} = "()";
	$ptg{debug} = "PARENTHESIS:()";
	parse_debug("parse_parenthesis", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_func
#------------------------------------------------------------------------------
sub parse_func {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	$ptg{function_index} = unpack("v", $buffer);
	$ptg{function_name} = $FUNCTION_NAME[$ptg{function_index}];
	$ptg{num_operands} = $FUNCTION_NUM_PARMS{$ptg{function_name}};
	$ptg{string} = $ptg{function_name} . "()";
	$ptg{debug} = "FUNCTION" . map_id_to_suffix($id) . ":function_index=$ptg{function_index}:function_name=$ptg{function_name}:num_operands=$ptg{num_operands}";
	debug("$ptg{debug} = $ptg{debug}") if $VERBOSE_DEBUG;
	parse_debug("parse_func", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_func_var
#------------------------------------------------------------------------------
sub parse_func_var {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	($ptg{num_operands}, $ptg{function_index}) = unpack("C v", $buffer);

	$ptg{function_name} = $FUNCTION_NAME[$ptg{function_index}];
	$ptg{string} = $ptg{function_name} . "()";
	$ptg{debug} = "FUNCTION" . map_id_to_suffix($id) . ":function_index=$ptg{function_index}:function_name=$ptg{function_name}:num_operands=$ptg{num_operands}";
	debug("ptg{debug} = $ptg{debug}") if $VERBOSE_DEBUG;
	parse_debug("parse_func_var", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_number
#------------------------------------------------------------------------------
sub parse_number {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	$ptg{number_value} = unpack("V", $buffer);

	$ptg{string} = "$ptg{number_value}";
	$ptg{debug} = "NUMBER:number_value=$ptg{number_value}";
	parse_debug("parse_number", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_string
#------------------------------------------------------------------------------
sub parse_string {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	($ptg{string_len}, $ptg{options}) = unpack("C2", $buffer);
	$ptg{size} = 3 + $ptg{string_len};
	$ptg{string} = '"' . substr($buffer, 2, $ptg{string_len}) . '"';
	$ptg{debug} = "STRING:options=$ptg{options},string_len=$ptg{string_len},string=\"$ptg{string}\"";
	parse_debug("parse_string", $id, $buffer, $ptg{string}, $ptg{debug});
	debug(sprintf("iR=%d, iC=%d, buffer=0x%s, buffer=%s, debug=%s", $iR, $iC, unpack("H*", $buffer), join(',',unpack("C*", $buffer)), $ptg{debug})) if $VERBOSE_DEBUG;

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_name
#------------------------------------------------------------------------------
sub parse_name {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	$ptg{label_index} = unpack("v", $buffer);

	$ptg{string} = "$ptg{label_index}";
	$ptg{debug} = "NAME" . map_id_to_suffix($id) . ":label_index=$ptg{label_index}";
	parse_debug("parse_name", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_name_x
#------------------------------------------------------------------------------
sub parse_name_x {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	($ptg{external_sheet_index}, $ptg{external_table_index}) = unpack("v2", $buffer);

	$ptg{string} = "$ptg{external_sheet_index}:$ptg{external_table_index}";
	$ptg{debug} = "NAME_X" . map_id_to_suffix($id) . ":external_sheet_index=$ptg{external_sheet_index}:external_table_index=$ptg{external_table_index}";
	parse_debug("parse_name_x", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_exp
#------------------------------------------------------------------------------
sub parse_exp {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	$ptg{buffer} = $buffer;

	$ptg{string} = "$ptg{buffer}";
	$ptg{debug} = "SHARED_EXPRESSION:buffer=\"$buffer\"";
	parse_debug("parse_exp", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_area_3d
#------------------------------------------------------------------------------
sub parse_area_3d {
	my ($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my (%ptg) = %$ptg_ptr;

	($ptg{external_sheet_index}, $ptg{first_row}, $ptg{last_row}, $ptg{first_col}, $ptg{last_col}) = unpack("v*", $buffer);

	$ptg{string} = "$ptg{external_sheet_index}:$ptg{first_row}:$ptg{last_row}:$ptg{first_col}:$ptg{last_col}";
	$ptg{debug} = "AREA_3D" . map_id_to_suffix($id) . ":external_sheet_index=$ptg{external_sheet_index}:first_row=$ptg{first_row}";
	parse_debug("parse_area_3d", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_ref_3d
#------------------------------------------------------------------------------
sub parse_ref_3d {
	my($iR, $iC, $id, $ptg_ptr, $buffer) = @_;
	my(%ptg) = %$ptg_ptr;

	($ptg{external_sheet_index}, $ptg{row}, $ptg{col}) = unpack("v*", $buffer);

	$ptg{string} = "$ptg{external_sheet_index}:$ptg{row}:$ptg{col}";
	$ptg{debug} = "REF_3D" . map_id_to_suffix($id) . ":external_sheet_index=$ptg{external_sheet_index}:row=$ptg{row}:col=$ptg{col}";
	parse_debug("parse_ref_3d", $id, $buffer, $ptg{string}, $ptg{debug});

	return \%ptg;
}
#------------------------------------------------------------------------------
# parse_debug
#------------------------------------------------------------------------------
sub parse_debug {
	return if !$VERBOSE_DEBUG;

	my($function_name, $id, $buffer, $string, $debug) = @_;

	print "$function_name: id=$id, buffer=\"$buffer\", string=\"$string\", debug=\"$debug\"\n";
}
#------------------------------------------------------------------------------
# print_hash
#------------------------------------------------------------------------------
sub print_hash {
	my($hash_name, $hash_ptr) = @_;
	print("Hash $hash_name:\n");
	my(%hash) = %{$hash_ptr};
	while (my($key, $value) = each(%hash)) {
		print("\t$key=$value\n");
	}
}
#------------------------------------------------------------------------------
# hash_to_string
#------------------------------------------------------------------------------
sub hash_to_string {
	my($hash_name, $hash_ptr) = @_;
	my($output);
	$output .= "Hash " . $hash_name . "->";
	my(%hash) = %{$hash_ptr};
	while (my($key, $value) = each(%hash)) {
		$output .= " $key=$value";
	}
	return $output;
}
#------------------------------------------------------------------------------
# map_id_to_suffix
#------------------------------------------------------------------------------
sub map_id_to_suffix {
	my($id) = @_;

	return ""		if ($id >= $BEGIN_REF_CLASS   && $id <= $END_REF_CLASS);
	return "_VALUE" if ($id >= $BEGIN_VALUE_CLASS && $id <= $END_VALUE_CLASS);
	return "_ARRAY" if ($id >= $BEGIN_ARRAY_CLASS && $id <= $END_ARRAY_CLASS);
}
#------------------------------------------------------------------------------
# binary_operator_to_infix
#------------------------------------------------------------------------------
sub binary_operator_to_infix {
	my($ptg_ptr, @operands) = @_;
	my(%ptg) = %$ptg_ptr;

	return "$operands[0]$ptg{string}$operands[1]";
}
#------------------------------------------------------------------------------
# unary_operator_to_infix
#------------------------------------------------------------------------------
sub unary_operator_to_infix {
	my($ptg_ptr, $operand) = @_;
	my(%ptg) = %$ptg_ptr;

	return "$operand$ptg{string}";
}
#------------------------------------------------------------------------------
# parenthesis_to_infix
#------------------------------------------------------------------------------
sub parenthesis_to_infix {
	my($ptg_ptr, $operand) = @_;
	my(%ptg) = %$ptg_ptr;

	return "(" . $operand . ")";
}
#------------------------------------------------------------------------------
# attr_to_infix
#------------------------------------------------------------------------------
sub attr_to_infix {
	my($ptg_ptr, $operand) = @_;
	my(%ptg) = %$ptg_ptr;

	#	There's only one ATTR token that behaves like a real operator: SUM
	return "SUM(" . $operand . ")";
}
#------------------------------------------------------------------------------
# func_to_infix
#------------------------------------------------------------------------------
sub func_to_infix() {
	my($ptg_ptr, @operands) = @_;
	my(%ptg) = %$ptg_ptr;

	return $ptg{function_name} . "(" . join(',',@operands) . ")";
}
#------------------------------------------------------------------------------
# _subString (for Spreadsheet::ParseExcel2)  DK:P414
#------------------------------------------------------------------------------
sub _subString($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
#Position (not enough for ARRAY)

    my $iPos = $oBook->{_PrevPos};
    return undef unless($iPos);
    $oBook->{_PrevPos} = undef;
    my ($iR, $iC, $iF) = @$iPos;

    my ($iLen, $sTxt, $sCode);
    if($oBook->{BIFFVersion} == verBIFF8) {
        my( $raBuff, $iLen) = _convBIFF8String($oBook, $sWk, 1);
        $sTxt  = $raBuff->[0];
        $sCode = ($raBuff->[1])? 'ucs2': undef;
		debug("iR=$iR, iC=$iC, iF=$iF, raBuff=$raBuff, iLen=$iLen, sTxt=$sTxt, sCode=$sCode") if $VERBOSE_DEBUG;
    }
    elsif($oBook->{BIFFVersion} == verBIFF5) {
        $sCode = '_native_';
        $iLen = unpack("v", $sWk);
        $sTxt = substr($sWk, 2, $iLen);
    }
    else {
        $sCode = '_native_';
        $iLen = unpack("c", $sWk);
        $sTxt = substr($sWk, 1, $iLen);
    }
    _NewCell (
            $oBook, $iR, $iC,
            Kind    => 'Formula String',
            Val     => $sTxt,
            FormatNo=> $iF,
            Format  => $oBook->{Format}[$iF],
            Numeric => 0,
            Code    => $sCode,
            Book    => $oBook,
        );
#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iC, $iC);
}
#------------------------------------------------------------------------------
# _subLabel (for Spreadsheet::ParseExcel2)   DK:P344
#------------------------------------------------------------------------------
sub _subLabel($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my($iR, $iC, $iF) = unpack("v3", $sWk);
    my ($sLbl, $sCode);
    #BIFF8
    if($oBook->{BIFFVersion} >= verBIFF8) {
        my ( $raBuff, $iLen, $iStPos, $iLenS) = 
                _convBIFF8String($oBook, substr($sWk,6), 1);
        $sLbl  = $raBuff->[0];
        $sCode = ($raBuff->[1])? 'ucs2': undef;
    }
    #Before BIFF8
    else {
        $sLbl  = substr($sWk,8);
        $sCode = '_native_';
    }
    _NewCell ( 
            $oBook, $iR, $iC,
            Kind    => 'Label',
            Val     => $sLbl,
            FormatNo=> $iF,
            Format  => $oBook->{Format}[$iF],
            Numeric => 0,
            Code    => $sCode,
            Book    => $oBook,
        );
#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iC, $iC);
}
#------------------------------------------------------------------------------
# _subMulRK (for Spreadsheet::ParseExcel2)   DK:P349
#------------------------------------------------------------------------------
sub _subMulRK($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return if $oBook->{SheetCount} <= 0;

    my ($iR, $iSc) = unpack("v2", $sWk);
    my $iEc = unpack("v", substr($sWk, length($sWk) -2, 2));

    my $iPos = 4;
    for(my $iC=$iSc; $iC<=$iEc; $iC++) {
        my($iF, $lVal) = _UnpackRKRec(substr($sWk, $iPos, 6), $iR, $iC);
        _NewCell (
                $oBook, $iR, $iC,
                Kind    => 'MulRK',
                Val     => $lVal,
                FormatNo=> $iF,
                Format  => $oBook->{Format}[$iF],
                Numeric => 1,
                Code => undef,
                Book    => $oBook,
                );
        $iPos += 6;
    }
#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iSc, $iEc);
}
#------------------------------------------------------------------------------
# _subMulBlank (for Spreadsheet::ParseExcel2) DK:P349
#------------------------------------------------------------------------------
sub _subMulBlank($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my ($iR, $iSc) = unpack("v2", $sWk);
    my $iEc = unpack("v", substr($sWk, length($sWk)-2, 2));
    my $iPos = 4;
    for(my $iC=$iSc; $iC<=$iEc; $iC++) {
        my $iF = unpack('v', substr($sWk, $iPos, 2));
        _NewCell (
                $oBook, $iR, $iC,
                Kind    => 'MulBlank',
                Val     => '',
                FormatNo=> $iF,
                Format  => $oBook->{Format}[$iF],
                Numeric => 0,
                Code    => undef,
                Book    => $oBook,
            );
        $iPos+=2;
    }
#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iSc, $iEc);
}
#------------------------------------------------------------------------------
# _subLabelSST (for Spreadsheet::ParseExcel2) DK: P345
#------------------------------------------------------------------------------
sub _subLabelSST($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my ($iR, $iC, $iF, $iIdx) = unpack('v3V', $sWk);

    _NewCell (
            $oBook, $iR, $iC,
            Kind    => 'PackedIdx',
            Val     => $oBook->{PkgStr}[$iIdx]->{Text},
            FormatNo=> $iF,
            Format  => $oBook->{Format}[$iF],
            Numeric => 0,
            Code    => ($oBook->{PkgStr}[$iIdx]->{Unicode})? 'ucs2': undef,
            Book    => $oBook,
            Rich   => $oBook->{PkgStr}[$iIdx]->{Rich},
        );

#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iC, $iC);
}
#------------------------------------------------------------------------------
# _subFlg1904 (for Spreadsheet::ParseExcel2) DK:P296
#------------------------------------------------------------------------------
sub _subFlg1904($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    $oBook->{Flg1904} = unpack("v", $sWk);
}
#------------------------------------------------------------------------------
# _subRow (for Spreadsheet::ParseExcel2) DK:P403
#------------------------------------------------------------------------------
sub _subRow($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});

#0. Get Worksheet info (MaxRow, MaxCol, MinRow, MinCol)
    my($iR, $iSc, $iEc, $iHght, $undef1, $undef2, $iGr, $iXf) = unpack("v8", $sWk);
    $iEc--;

#1. RowHeight
    if($iGr & 0x20) {   #Height = 0
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{RowHeight}[$iR] = 0;
    }
    else {
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{RowHeight}[$iR] = $iHght/20.0;
    }

#2.MaxRow, MaxCol, MinRow, MinCol
    _SetDimension($oBook, $iR, $iSc, $iEc);
}
#------------------------------------------------------------------------------
# _SetDimension (for Spreadsheet::ParseExcel2)
#------------------------------------------------------------------------------
sub _SetDimension($$$$)
{
    my($oBook, $iR, $iSc, $iEc)=@_;
    return undef unless(defined $oBook->{_CurSheet});

#2.MaxRow, MaxCol, MinRow, MinCol
#2.1 MinRow
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{MinRow} = $iR 
        unless (defined $oBook->{Worksheet}[$oBook->{_CurSheet}]->{MinRow}) and 
               ($oBook->{Worksheet}[$oBook->{_CurSheet}]->{MinRow} <= $iR);

#2.2 MaxRow
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{MaxRow} = $iR 
        unless (defined $oBook->{Worksheet}[$oBook->{_CurSheet}]->{MaxRow}) and
               ($oBook->{Worksheet}[$oBook->{_CurSheet}]->{MaxRow} > $iR);
#2.3 MinCol
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{MinCol} = $iSc
            unless (defined $oBook->{Worksheet}[$oBook->{_CurSheet}]->{MinCol}) and
               ($oBook->{Worksheet}[$oBook->{_CurSheet}]->{MinCol} <= $iSc);
#2.4 MaxCol
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{MaxCol} = $iEc 
            unless (defined $oBook->{Worksheet}[$oBook->{_CurSheet}]->{MaxCol}) and
               ($oBook->{Worksheet}[$oBook->{_CurSheet}]->{MaxCol} > $iEc);

}
#------------------------------------------------------------------------------
# _subDefaultRowHeight (for Spreadsheet::ParseExcel2)    DK: P318
#------------------------------------------------------------------------------
sub _subDefaultRowHeight($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});
#1. RowHeight
    my($iDum, $iHght) = unpack("v2", $sWk);
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{DefRowHeight} = $iHght/20;

}
#------------------------------------------------------------------------------
# _subStandardWidth(for Spreadsheet::ParseExcel2)    DK:P413
#------------------------------------------------------------------------------
sub _subStandardWidth($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my $iW = unpack("v", $sWk);
    $oBook->{StandardWidth}= _adjustColWidth($oBook, $iW);
}
#------------------------------------------------------------------------------
# _subDefColWidth(for Spreadsheet::ParseExcel2)      DK:P319
#------------------------------------------------------------------------------
sub _subDefColWidth($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});
    my $iW = unpack("v", $sWk);
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{DefColWidth}= _adjustColWidth($oBook, $iW);
}
#------------------------------------------------------------------------------
# _adjustColWidth (for Spreadsheet::ParseExcel2)
#------------------------------------------------------------------------------
sub _adjustColWidth($$) {
    my($oBook, $iW)=@_;
    return (($iW -0xA0)/256);
#    ($oBook->{Worksheet}[$oBook->{_CurSheet}]->{SheetVersion} == verExcel97)?
#        (($iW -0xA0)/256) : $iW;
}
#------------------------------------------------------------------------------
# _subColInfo (for Spreadsheet::ParseExcel2) DK:P309
#------------------------------------------------------------------------------
sub _subColInfo($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});
    my($iSc, $iEc, $iW, $iXF, $iGr) = unpack("v5", $sWk);
    for(my $i= $iSc; $i<=$iEc; $i++) {
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{ColWidth}[$i] = 
                        ($iGr & 0x01)? 0: _adjustColWidth($oBook, $iW);
                    #0x01 means HIDDEN
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{ColFmtNo}[$i] = $iXF;
        # $oBook->{Worksheet}[$oBook->{_CurSheet}]->{ColCr}[$i]    = $iGr; #Not Implemented
    }
}
#------------------------------------------------------------------------------
# _subSST (for Spreadsheet::ParseExcel2) DK:P413
#------------------------------------------------------------------------------
sub _subSST($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    _subStrWk($oBook, substr($sWk, 8));
}
#------------------------------------------------------------------------------
# _subContinue (for Spreadsheet::ParseExcel2)    DK:P311
#------------------------------------------------------------------------------
sub _subContinue($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
=cmmt
    if(defined $oThis->{FuncTbl}->{$bOp}) {
        $oThis->{FuncTbl}->{$PREFUNC}->($oBook, $bOp, $bLen, $sWk);
    }
=cut
    _subStrWk($oBook, $sWk, 1) if($PREFUNC == 0xFC);
}
#------------------------------------------------------------------------------
# _subWriteAccess (for Spreadsheet::ParseExcel2) DK:P451
#------------------------------------------------------------------------------
sub _subWriteAccess($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return if defined $oBook->{_Author};

    #BIFF8
    if($oBook->{BIFFVersion} >= verBIFF8) {
        $oBook->{Author} = _convBIFF8String($oBook, $sWk);
    }
    #Before BIFF8
    else {
        my($iLen) = unpack("c", $sWk);
        $oBook->{Author} = $oBook->{FmtClass}->TextFmt(substr($sWk, 1, $iLen), '_native_');
    }
}
#------------------------------------------------------------------------------
# _convBIFF8String (for Spreadsheet::ParseExcel2)
#------------------------------------------------------------------------------
sub _convBIFF8String($$;$){
    my($oBook, $sWk, $iCnvFlg) = @_;
    my($iLen, $iFlg) = unpack("vc", $sWk);
    my($iHigh, $iExt, $iRich) = ($iFlg & 0x01, $iFlg & 0x04, $iFlg & 0x08);
    my($iStPos, $iExtCnt, $iRichCnt, $sStr);
#2. Rich and Ext
    if($iRich && $iExt) {
        $iStPos   = 9;
        ($iRichCnt, $iExtCnt) = unpack('vV', substr($sWk, 3, 6));
    }
    elsif($iRich) { #Only Rich
        $iStPos   = 5;
        $iRichCnt = unpack('v', substr($sWk, 3, 2));
        $iExtCnt  = 0;
    }
    elsif($iExt)  { #Only Ext
        $iStPos   = 7;
        $iRichCnt = 0;
        $iExtCnt  = unpack('V', substr($sWk, 3, 4));
    }
    else {          #Nothing Special
        $iStPos   = 3;
        $iExtCnt  = 0;
        $iRichCnt = 0;
    }
#3.Get String
    if($iHigh) {    #Compressed
        $iLen *= 2;
        $sStr = substr($sWk,    $iStPos, $iLen);
        _SwapForUnicode(\$sStr);
        $sStr = $oBook->{FmtClass}->TextFmt($sStr, 'ucs2') unless($iCnvFlg);
    }
    else {              #Not Compressed
        $sStr = substr($sWk, $iStPos, $iLen);
        $sStr = $oBook->{FmtClass}->TextFmt($sStr, undef) unless($iCnvFlg);
    }

#4. return 
    if(wantarray) {
        #4.1 Get Rich and Ext
        if(length($sWk) < $iStPos + $iLen+ $iRichCnt*4+$iExtCnt) {
            return ([undef, $iHigh, undef, undef], 
                $iStPos + $iLen+ $iRichCnt*4+$iExtCnt, $iStPos, $iLen);
        }
        else {
            return ([$sStr, $iHigh,
                    substr($sWk, $iStPos + $iLen, $iRichCnt*4),
                    substr($sWk, $iStPos + $iLen+ $iRichCnt*4, $iExtCnt)], 
                $iStPos + $iLen+ $iRichCnt*4+$iExtCnt,  $iStPos, $iLen);
        }
    }
    else {
        return $sStr;
    }
}
#------------------------------------------------------------------------------
# _subXF (for Spreadsheet::ParseExcel2)     DK:P453
#------------------------------------------------------------------------------
sub _subXF($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;

    my ($iFnt, $iIdx);
    my($iLock, $iHidden, $iStyle, $i123, $iAlH, $iWrap, $iAlV, $iJustL, $iRotate,
        $iInd, $iShrink, $iMerge, $iReadDir, $iBdrD,
        $iBdrSL, $iBdrSR, $iBdrST, $iBdrSB, $iBdrSD,
        $iBdrCL, $iBdrCR, $iBdrCT, $iBdrCB, $iBdrCD,
        $iFillP, $iFillCF, $iFillCB);

    if($oBook->{BIFFVersion} == verBIFF8) {
        my ($iGen, $iAlign, $iGen2, $iBdr1,  $iBdr2, $iBdr3, $iPtn );

        ($iFnt, $iIdx, $iGen, $iAlign, $iGen2, $iBdr1,  $iBdr2, $iBdr3, $iPtn )
            = unpack("v7Vv", $sWk);
        $iLock   = ($iGen & 0x01)? 1:0;
        $iHidden = ($iGen & 0x02)? 1:0;
        $iStyle  = ($iGen & 0x04)? 1:0;
        $i123    = ($iGen & 0x08)? 1:0;
        $iAlH    = ($iAlign & 0x07);
        $iWrap   = ($iAlign & 0x08)? 1:0;
        $iAlV    = ($iAlign & 0x70) / 0x10;
        $iJustL  = ($iAlign & 0x80)? 1:0;

        $iRotate  = (($iAlign & 0xFF00) / 0x100) & 0x00FF;
        $iRotate = 90 if($iRotate == 255);
        $iRotate = 90 - $iRotate if($iRotate > 90);

        $iInd     = ($iGen2 & 0x0F);
        $iShrink  = ($iGen2 & 0x10)? 1:0;
        $iMerge   = ($iGen2 & 0x20)? 1:0;
        $iReadDir = (($iGen2 & 0xC0) / 0x40) & 0x03;
        $iBdrSL = $iBdr1 & 0x0F;
        $iBdrSR = (($iBdr1 & 0xF0)   / 0x10)   & 0x0F;
        $iBdrST = (($iBdr1 & 0xF00)  / 0x100)  & 0x0F;
        $iBdrSB = (($iBdr1 & 0xF000) / 0x1000) & 0x0F;

        $iBdrCL = (($iBdr2 & 0x7F)) & 0x7F;
        $iBdrCR = (($iBdr2 & 0x3F80) / 0x80) & 0x7F;
        $iBdrD  = (($iBdr2 & 0xC000) / 0x4000) & 0x3;

        $iBdrCT = (($iBdr3 & 0x7F)) & 0x7F;
        $iBdrCB = (($iBdr3 & 0x3F80) / 0x80) & 0x7F;
        $iBdrCD = (($iBdr3 & 0x1FC000) / 0x4000) & 0x7F;
        $iBdrSD = (($iBdr3 & 0x1E00000) / 0x200000) & 0xF;
        $iFillP = (($iBdr3 & 0xFC000000) / 0x4000000) & 0x3F;

        $iFillCF = ($iPtn & 0x7F);
        $iFillCB = (($iPtn & 0x3F80) / 0x80) & 0x7F;
    }
    else {
        my ($iGen, $iAlign, $iPtn,  $iPtn2, $iBdr1, $iBdr2);

        ($iFnt, $iIdx, $iGen, $iAlign, $iPtn,  $iPtn2, $iBdr1, $iBdr2)
            = unpack("v8", $sWk);
        $iLock   = ($iGen & 0x01)? 1:0;
        $iHidden = ($iGen & 0x02)? 1:0;
        $iStyle  = ($iGen & 0x04)? 1:0;
        $i123    = ($iGen & 0x08)? 1:0;

        $iAlH    = ($iAlign & 0x07);
        $iWrap  = ($iAlign & 0x08)? 1:0;
        $iAlV    = ($iAlign & 0x70) / 0x10;
        $iJustL  = ($iAlign & 0x80)? 1:0;

        $iRotate  = (($iAlign & 0x300) / 0x100) & 0x3;

        $iFillCF = ($iPtn & 0x7F);
        $iFillCB = (($iPtn & 0x1F80) / 0x80) & 0x7F;

        $iFillP = ($iPtn2 & 0x3F);
        $iBdrSB  = (($iPtn2 & 0x1C0) /  0x40) & 0x7;
        $iBdrCB = (($iPtn2 & 0xFE00) / 0x200) & 0x7F;

        $iBdrST = ($iBdr1 & 0x07);
        $iBdrSL = (($iBdr1 & 0x38)   / 0x8)   & 0x07;
        $iBdrSR = (($iBdr1 & 0x1C0)  / 0x40)  & 0x07;
        $iBdrCT = (($iBdr1 & 0xFE00) / 0x200)  & 0x7F;

        $iBdrCL = ($iBdr2  & 0x7F)  & 0x7F;
        $iBdrCR = (($iBdr2 & 0x3F80) / 0x80) & 0x7F;
    }

   push @{$oBook->{Format}} , 
         Spreadsheet::ParseExcel2::Format->new (
            FontNo   => $iFnt,
            Font     => $oBook->{Font}[$iFnt], 
            FmtIdx   => $iIdx,

            Lock     => $iLock,
            Hidden   => $iHidden,
            Style    => $iStyle,
            Key123   => $i123,
            AlignH   => $iAlH,
            Wrap     => $iWrap,
            AlignV   => $iAlV,
            JustLast => $iJustL,
            Rotate   => $iRotate,

            Indent   => $iInd,
            Shrink   => $iShrink,
            Merge    => $iMerge,
            ReadDir  => $iReadDir,

            BdrStyle => [$iBdrSL, $iBdrSR, $iBdrST, $iBdrSB],
            BdrColor => [$iBdrCL, $iBdrCR, $iBdrCT, $iBdrCB],
            BdrDiag  => [$iBdrD, $iBdrSD, $iBdrCD],
            Fill     => [$iFillP, $iFillCF, $iFillCB],
        );
}
#------------------------------------------------------------------------------
# _subFormat (for Spreadsheet::ParseExcel2)  DK: P336
#------------------------------------------------------------------------------
sub _subFormat($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my $sFmt;
    if (($oBook->{BIFFVersion} == verBIFF2) ||
        ($oBook->{BIFFVersion} == verBIFF3) ||
        ($oBook->{BIFFVersion} == verBIFF4) ||
        ($oBook->{BIFFVersion} == verBIFF5) ) {
        $sFmt = substr($sWk, 3, unpack('c', substr($sWk, 2, 1)));
        $sFmt = $oBook->{FmtClass}->TextFmt($sFmt, '_native_');
    }
    else {
        $sFmt = _convBIFF8String($oBook, substr($sWk, 2));
    }
    $oBook->{FormatStr}->{unpack('v', substr($sWk, 0, 2))} = $sFmt;
}
#------------------------------------------------------------------------------
# _subPalette (for Spreadsheet::ParseExcel2) DK: P393
#------------------------------------------------------------------------------
sub _subPalette($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    for(my $i=0;$i<unpack('v', $sWk);$i++) {
#        push @aColor, unpack('H6', substr($sWk, $i*4+2));
        $aColor[$i+8] = unpack('H6', substr($sWk, $i*4+2));
    }
}
#------------------------------------------------------------------------------
# _subFont (for Spreadsheet::ParseExcel2) DK:P333
#------------------------------------------------------------------------------
sub _subFont($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my($iHeight, $iAttr, $iCIdx, $iBold, $iSuper, $iUnderline, $sFntName);
    my($bBold, $bItalic, $bUnderline, $bStrikeout);

    if($oBook->{BIFFVersion} == verBIFF8) {
        ($iHeight, $iAttr, $iCIdx, $iBold, $iSuper, $iUnderline) = 
            unpack("v5c", $sWk);
        my($iSize, $iHigh) = unpack('cc', substr($sWk, 14, 2));
        if($iHigh) {
            $sFntName = substr($sWk, 16, $iSize*2);
            _SwapForUnicode(\$sFntName);
            $sFntName = $oBook->{FmtClass}->TextFmt($sFntName, 'ucs2');
        }
        else {
            $sFntName = substr($sWk, 16, $iSize);
            $sFntName = $oBook->{FmtClass}->TextFmt($sFntName, '_native_');
        }
        $bBold       = ($iBold >= 0x2BC)? 1: 0;
        $bItalic     = ($iAttr & 0x02)? 1: 0;
        $bStrikeout  = ($iAttr & 0x08)? 1: 0;
        $bUnderline  = ($iUnderline)? 1: 0;
    }
    elsif($oBook->{BIFFVersion} == verBIFF5) {
        ($iHeight, $iAttr, $iCIdx, $iBold, $iSuper, $iUnderline) = 
            unpack("v5c", $sWk);
        $sFntName = $oBook->{FmtClass}->TextFmt(
                    substr($sWk, 15, unpack("c", substr($sWk, 14, 1))), 
                    '_native_');
        $bBold       = ($iBold >= 0x2BC)? 1: 0;
        $bItalic     = ($iAttr & 0x02)? 1: 0;
        $bStrikeout  = ($iAttr & 0x08)? 1: 0;
        $bUnderline  = ($iUnderline)? 1: 0;
    }
    else {
        ($iHeight, $iAttr) = unpack("v2", $sWk);
        $iCIdx       = undef;
        $iSuper      = 0;

        $bBold       = ($iAttr & 0x01)? 1: 0;
        $bItalic     = ($iAttr & 0x02)? 1: 0;
        $bUnderline  = ($iAttr & 0x04)? 1: 0;
        $bStrikeout  = ($iAttr & 0x08)? 1: 0;

        $sFntName = substr($sWk, 5, unpack("c", substr($sWk, 4, 1)));
    }
    push @{$oBook->{Font}}, 
        Spreadsheet::ParseExcel2::Font->new(
            Height          => $iHeight / 20.0,
            Attr            => $iAttr,
            Color           => $iCIdx,
            Super           => $iSuper,
            UnderlineStyle  => $iUnderline,
            Name            => $sFntName,

            Bold            => $bBold,
            Italic          => $bItalic,
            Underline       => $bUnderline,
            Strikeout       => $bStrikeout,
    );
    #Skip Font[4]
    push @{$oBook->{Font}}, {} if(scalar(@{$oBook->{Font}}) == 4);

}
#------------------------------------------------------------------------------
# _subBoundSheet (for Spreadsheet::ParseExcel2): DK: P307
#------------------------------------------------------------------------------
sub _subBoundSheet($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my($iPos, $iGr, $iKind) = unpack("Lc2", $sWk);
    $iKind &= 0x0F;
    return if(($iKind != 0x00) && ($iKind != 0x01));

    if($oBook->{BIFFVersion} >= verBIFF8) {
        my($iSize, $iUni) = unpack("cc", substr($sWk, 6, 2));
        my $sWsName = substr($sWk, 8);
        if($iUni & 0x01) {
            _SwapForUnicode(\$sWsName);
            $sWsName = $oBook->{FmtClass}->TextFmt($sWsName, 'ucs2');
        }
        $oBook->{Worksheet}[$oBook->{SheetCount}] = 
            new Spreadsheet::ParseExcel2::Worksheet(
                    Name => $sWsName,
                    Kind => $iKind,
                    _Pos => $iPos,
                    _Book => $oBook,
                    _SheetNo => $oBook->{SheetCount},
                );
    }
    else {
        $oBook->{Worksheet}[$oBook->{SheetCount}] = 
            new Spreadsheet::ParseExcel2::Worksheet(
                    Name => $oBook->{FmtClass}->TextFmt(substr($sWk, 7), '_native_'),
                    Kind => $iKind,
                    _Pos => $iPos,
                    _Book => $oBook,
                    _SheetNo => $oBook->{SheetCount},
                );
    }
    $oBook->{SheetCount}++;
}
#------------------------------------------------------------------------------
# _subHeader (for Spreadsheet::ParseExcel2) DK: P340
#------------------------------------------------------------------------------
sub _subHeader($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});
    my $sW;
    #BIFF8
    if($oBook->{BIFFVersion} >= verBIFF8) {
    $sW = _convBIFF8String($oBook, $sWk);
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{Header} = 
        ($sW eq "\x00")? undef : $sW;
    }
    #Before BIFF8
    else {
        my($iLen) = unpack("c", $sWk);
    $sW = $oBook->{FmtClass}->TextFmt(substr($sWk, 1, $iLen), '_native_');
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{Header} =
        ($sW eq "\x00\x00\x00")? undef : $sW;
    }
}
#------------------------------------------------------------------------------
# _subFooter (for Spreadsheet::ParseExcel2) DK: P335
#------------------------------------------------------------------------------
sub _subFooter($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});
    my $sW;
    #BIFF8
    if($oBook->{BIFFVersion} >= verBIFF8) {
    $sW = _convBIFF8String($oBook, $sWk);
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{Footer} = 
        ($sW eq "\x00")? undef : $sW;
    }
    #Before BIFF8
    else {
        my($iLen) = unpack("c", $sWk);
    $sW = $oBook->{FmtClass}->TextFmt(substr($sWk, 1, $iLen), '_native_');
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{Footer} = 
        ($sW eq "\x00\x00\x00")? undef : $sW;
    }
}
#------------------------------------------------------------------------------
# _subHPageBreak (for Spreadsheet::ParseExcel2) DK: P341
#------------------------------------------------------------------------------
sub _subHPageBreak($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my @aBreak;
    my $iCnt = unpack("v", $sWk);

    return undef unless(defined $oBook->{_CurSheet});
    #BIFF8
    if($oBook->{BIFFVersion} >= verBIFF8) {
        for(my $i=0;$i<$iCnt;$i++) {
            my($iRow, $iColB, $iColE) = 
                    unpack('v3', substr($sWk, 2 + $i*6, 6));
#            push @aBreak, [$iRow, $iColB, $iColE];
            push @aBreak, $iRow;
        }
    }
    #Before BIFF8
    else {
        for(my $i=0;$i<$iCnt;$i++) {
            my($iRow) = 
                    unpack('v', substr($sWk, 2 + $i*2, 2));
            push @aBreak, $iRow;
#            push @aBreak, [$iRow, 0, 255];
        }
    }
    @aBreak = sort {$a <=> $b} @aBreak;
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{HPageBreak} = \@aBreak;
}
#------------------------------------------------------------------------------
# _subVPageBreak (for Spreadsheet::ParseExcel2) DK: P447
#------------------------------------------------------------------------------
sub _subVPageBreak($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});

    my @aBreak;
    my $iCnt = unpack("v", $sWk);
    #BIFF8
    if($oBook->{BIFFVersion} >= verBIFF8) {
        for(my $i=0;$i<$iCnt;$i++) {
            my($iCol, $iRowB, $iRowE) = 
                    unpack('v3', substr($sWk, 2 + $i*6, 6));
            push @aBreak, $iCol;
#            push @aBreak, [$iCol, $iRowB, $iRowE];
        }
    }
    #Before BIFF8
    else {
        for(my $i=0;$i<$iCnt;$i++) {
            my($iCol) = 
                    unpack('v', substr($sWk, 2 + $i*2, 2));
            push @aBreak, $iCol;
#            push @aBreak, [$iCol, 0, 65535];
        }
    }
    @aBreak = sort {$a <=> $b} @aBreak;
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{VPageBreak} = \@aBreak;
}
#------------------------------------------------------------------------------
# _subMergin (for Spreadsheet::ParseExcel2) DK: P306, 345, 400, 440
#------------------------------------------------------------------------------
sub _subMergin($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});

    my $dWk = _convDval(substr($sWk, 0, 8)) * 127 / 50;
    if($bOp == 0x26) {
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{LeftMergin} = $dWk;
    }
    elsif($bOp == 0x27) {
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{RightMergin} = $dWk;
    }
    elsif($bOp == 0x28) {
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{TopMergin} = $dWk;
    }
    elsif($bOp == 0x29) {
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{BottomMergin} = $dWk;
    }
}
#------------------------------------------------------------------------------
# _subHcenter (for Spreadsheet::ParseExcel2) DK: P340
#------------------------------------------------------------------------------
sub _subHcenter($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});

    my $iWk = unpack("v", $sWk);
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{HCenter} = $iWk;

}
#------------------------------------------------------------------------------
# _subVcenter (for Spreadsheet::ParseExcel2) DK: P447
#------------------------------------------------------------------------------
sub _subVcenter($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});

    my $iWk = unpack("v", $sWk);
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{VCenter} = $iWk;
}
#------------------------------------------------------------------------------
# _subPrintGridlines (for Spreadsheet::ParseExcel2) DK: P397
#------------------------------------------------------------------------------
sub _subPrintGridlines($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});

    my $iWk = unpack("v", $sWk);
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{PrintGrid} = $iWk;

}
#------------------------------------------------------------------------------
# _subPrintHeaders (for Spreadsheet::ParseExcel2) DK: P397
#------------------------------------------------------------------------------
sub _subPrintHeaders($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});

    my $iWk = unpack("v", $sWk);
    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{PrintHeaders} = $iWk;
}
#------------------------------------------------------------------------------
# _subSETUP (for Spreadsheet::ParseExcel2) DK: P409
#------------------------------------------------------------------------------
sub _subSETUP($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});

    my $oWkS = $oBook->{Worksheet}[$oBook->{_CurSheet}];
    my $iGrBit;

    ($oWkS->{PaperSize},
     $oWkS->{Scale}    ,
     $oWkS->{PageStart},
     $oWkS->{FitWidth} ,
     $oWkS->{FitHeight},
     $iGrBit,
     $oWkS->{Res},
     $oWkS->{VRes},) = unpack('v8', $sWk);

    $oWkS->{HeaderMergin} = _convDval(substr($sWk, 16, 8)) * 127 / 50;
    $oWkS->{FooterMergin} = _convDval(substr($sWk, 24, 8)) * 127 / 50;
    $oWkS->{Copis}= unpack('v2', substr($sWk, 32, 2));
    $oWkS->{LeftToRight}= (($iGrBit & 0x01)? 1: 0);
    $oWkS->{Landscape}  = (($iGrBit & 0x02)? 1: 0);
    $oWkS->{NoPls}      = (($iGrBit & 0x04)? 1: 0);
    $oWkS->{NoColor}    = (($iGrBit & 0x08)? 1: 0);
    $oWkS->{Draft}      = (($iGrBit & 0x10)? 1: 0);
    $oWkS->{Notes}      = (($iGrBit & 0x20)? 1: 0);
    $oWkS->{NoOrient}   = (($iGrBit & 0x40)? 1: 0);
    $oWkS->{UsePage}    = (($iGrBit & 0x80)? 1: 0);
}
#------------------------------------------------------------------------------
# _subName (for Spreadsheet::ParseExcel2) DK: P350
#------------------------------------------------------------------------------
sub _subName($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    my($iGrBit, 
        $cKey, $cCh, 
        $iCce, $ixAls, $iTab,
        $cchCust, $cchDsc, $cchHep, $cchStatus) = unpack('vc2v3c4', $sWk);
#Builtin Name + Length == 1
    if(($iGrBit & 0x20) && ($cCh == 1)) {
        #BIFF8
        if($oBook->{BIFFVersion} >= verBIFF8) {
            my $iName  = unpack('n', substr($sWk, 14 ));
            my $iSheet = unpack('v', substr($sWk, 8 )) - 1;
            if($iName == 6) {       #PrintArea
                my($iSheetW, $raArea) = _ParseNameArea(substr($sWk, 16));
                $oBook->{PrintArea}[$iSheet] =  $raArea;
            }
            elsif($iName == 7) {    #Title
                my($iSheetW, $raArea) = _ParseNameArea(substr($sWk, 16));
                my @aTtlR = ();
                my @aTtlC = ();
                foreach my $raI (@$raArea) {
                    if($raI->[3] == 0xFF) { #Row Title
                        push @aTtlR, [$raI->[0], $raI->[2] ];
                    }
                    else {                  #Col Title
                        push @aTtlC, [$raI->[1], $raI->[3] ];
                    }
                }
                $oBook->{PrintTitle}[$iSheet] =  {Row => \@aTtlR, Column => \@aTtlC};
            }
        }
        else {
            my $iName = unpack('c', substr($sWk, 14 ));
            if($iName == 6) {       #PrintArea
                my($iSheet, $raArea) = _ParseNameArea95(substr($sWk, 15));
                $oBook->{PrintArea}[$iSheet] =  $raArea;
            }
            elsif($iName == 7) {    #Title
                my($iSheet, $raArea) = _ParseNameArea95(substr($sWk, 15));
                my @aTtlR = ();
                my @aTtlC = ();
                foreach my $raI (@$raArea) {
                    if($raI->[3] == 0xFF) { #Row Title
                        push @aTtlR, [$raI->[0], $raI->[2] ];
                    }
                    else {                  #Col Title
                        push @aTtlC, [$raI->[1], $raI->[3] ];
                    }
                }
                $oBook->{PrintTitle}[$iSheet] =  {Row => \@aTtlR, Column => \@aTtlC};
            }
        }
    }
}
#------------------------------------------------------------------------------
# ParseNameArea (for Spreadsheet::ParseExcel2) DK: 494 (ptgAread3d)
#------------------------------------------------------------------------------
sub _ParseNameArea($) {
    my ($sObj) =@_;
    my ($iOp);
    my @aRes = ();
    $iOp = unpack('C', $sObj);
    my $iSheet;
    if($iOp == 0x3b) {
        my($iWkS, $iRs, $iRe, $iCs, $iCe) = 
            unpack('v5', substr($sObj, 1));
        $iSheet = $iWkS;
        push @aRes, [$iRs, $iCs, $iRe, $iCe];
    }
    elsif($iOp == 0x29) {
        my $iLen = unpack('v', substr($sObj, 1, 2));
        my $iSt = 0;
        while($iSt < $iLen) {
            my($iOpW, $iWkS, $iRs, $iRe, $iCs, $iCe) = 
                unpack('cv5', substr($sObj, $iSt+3, 11));

            if($iOpW == 0x3b) {
                $iSheet = $iWkS;
                push @aRes, [$iRs, $iCs, $iRe, $iCe];
            }

            if($iSt==0) {
                $iSt += 11;
            }
            else {
                $iSt += 12; #Skip 1 byte;
            }
        }
    }
    return ($iSheet, \@aRes);
}
#------------------------------------------------------------------------------
# ParseNameArea95 (for Spreadsheet::ParseExcel2) DK: 494 (ptgAread3d)
#------------------------------------------------------------------------------
sub _ParseNameArea95($) {
    my ($sObj) =@_;
    my ($iOp);
    my @aRes = ();
    $iOp = unpack('C', $sObj);
    my $iSheet;
    if($iOp == 0x3b) {
        $iSheet = unpack('v', substr($sObj, 11, 2));
        my($iRs, $iRe, $iCs, $iCe) = 
                unpack('v2C2', substr($sObj, 15, 6));
        push @aRes, [$iRs, $iCs, $iRe, $iCe];
    }
    elsif($iOp == 0x29) {
        my $iLen = unpack('v', substr($sObj, 1, 2));
        my $iSt = 0;
        while($iSt < $iLen) {
            my $iOpW = unpack('c', substr($sObj, $iSt+3, 6));
            $iSheet = unpack('v', substr($sObj, $iSt+14, 2));
            my($iRs, $iRe, $iCs, $iCe) = 
                unpack('v2C2', substr($sObj, $iSt+18, 6));
            push @aRes, [$iRs, $iCs, $iRe, $iCe] if($iOpW == 0x3b);

            if($iSt==0) {
                $iSt += 21;
            }
            else {
                $iSt += 22; #Skip 1 byte;
            }
        }
    }
    return ($iSheet, \@aRes);
}
#------------------------------------------------------------------------------
# _subBOOL (for Spreadsheet::ParseExcel2) DK: P452
#------------------------------------------------------------------------------
sub _subWSBOOL($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});

    $oBook->{Worksheet}[$oBook->{_CurSheet}]->{PageFit} = 
                                ((unpack('v', $sWk) & 0x100)? 1: 0);
}
#------------------------------------------------------------------------------
# _subMergeArea (for Spreadsheet::ParseExcel2) DK: (Not)
#------------------------------------------------------------------------------
sub _subMergeArea($$$$)
{
    my($oBook, $bOp, $bLen, $sWk) = @_;
    return undef unless(defined $oBook->{_CurSheet});

    my $iCnt = unpack("v", $sWk);
    my $oWkS = $oBook->{Worksheet}[$oBook->{_CurSheet}];
    $oWkS->{MergedArea} = [] unless(defined $oWkS->{MergedArea});
    for(my $i=0; $i < $iCnt; $i++) {
        my($iRs, $iRe, $iCs, $iCe) = unpack('v4', substr($sWk, $i*8 + 2, 8));
        for(my $iR=$iRs;$iR<=$iRe;$iR++) {
            for(my $iC=$iCs;$iC<=$iCe;$iC++) {
                $oWkS->{Cells}[$iR][$iC] ->{Merged} = 1 
                        if(defined $oWkS->{Cells}[$iR][$iC] );
            }
        }
        push @{$oWkS->{MergedArea}}, [$iRs, $iCs, $iRe, $iCe];
    }
}
#------------------------------------------------------------------------------
# DecodeBoolErr (for Spreadsheet::ParseExcel2) DK: P306
#------------------------------------------------------------------------------
sub DecodeBoolErr($$)
{
    my($iVal, $iFlg) = @_;
    if($iFlg) {     # ERROR
        if($iVal == 0x00) {
            return "#NULL!";
        }
        elsif($iVal == 0x07) {
            return "#DIV/0!";
        }
        elsif($iVal == 0x0F) {
            return "#VALUE!";
        }
        elsif($iVal == 0x17) {
            return "#REF!";
        }
        elsif($iVal == 0x1D) {
            return "#NAME?";
        }
        elsif($iVal == 0x24) {
            return "#NUM!";
        }
        elsif($iVal == 0x2A) {
            return "#N/A!";
        }
        else {
            return "#ERR";
        }
    }
    else {
        return ($iVal)? "TRUE" : "FALSE";
    }
}
#------------------------------------------------------------------------------
# _UnpackRKRec (for Spreadsheet::ParseExcel2)    DK:P 401
#------------------------------------------------------------------------------
sub _UnpackRKRec($) {
    my($sArg) = @_;

    my $iF  = unpack('v', substr($sArg, 0, 2));

    my $lWk = substr($sArg, 2, 4);
    my $sWk = pack("c4", reverse(unpack("c4", $lWk)));
    my $iPtn = unpack("c",substr($sWk, 3, 1)) & 0x03;
    if($iPtn == 0) {
        return ($iF, unpack("d", ($BIGENDIAN)? $sWk . "\0\0\0\0": "\0\0\0\0". $lWk));
    }
    elsif($iPtn == 1) {
        substr($sWk, 3, 1) &=  pack('c', unpack("c",substr($sWk, 3, 1)) & 0xFC);
        substr($lWk, 0, 1) &=  pack('c', unpack("c",substr($lWk, 0, 1)) & 0xFC);
        return ($iF, unpack("d", ($BIGENDIAN)? $sWk . "\0\0\0\0": "\0\0\0\0". $lWk)/ 100);
    }
    elsif($iPtn == 2) {
    my $sUB = unpack("B32", $sWk);
        my $sWkLB = pack("B32", (substr($sUB, 0, 1) x 2) .
                                substr($sUB, 0, 30));
        my $sWkL  = ($BIGENDIAN)? $sWkLB: pack("c4", reverse(unpack("c4", $sWkLB)));
        return ($iF, unpack("i", $sWkL));
    }
    else {
    my $sUB = unpack("B32", $sWk);
        my $sWkLB = pack("B32", (substr($sUB, 0, 1) x 2) .
                                substr($sUB, 0, 30));
        my $sWkL  = ($BIGENDIAN)? $sWkLB: pack("c4", reverse(unpack("c4", $sWkLB)));
        return ($iF, unpack("i", $sWkL) / 100);
    }
}
#------------------------------------------------------------------------------
# _subStrWk (for Spreadsheet::ParseExcel2)     DK:P280 ..
#------------------------------------------------------------------------------
sub _subStrWk($$;$)
{
    my($oBook, $sWk, $fCnt) = @_;

    #1. Continue
    if(defined($fCnt)) {
    #1.1 Before No Data No
        if($oBook->{StrBuff} eq '') { #
#print "CONT NO DATA\n";
#print "DATA:", unpack('H30', $oBook->{StrBuff}), " PRE:$oBook->{_PrevCond}\n";
            $oBook->{StrBuff} .= $sWk;
        }
        #1.1 No PrevCond 
        elsif(!(defined($oBook->{_PrevCond}))) {
#print "NO PREVCOND\n";
                $oBook->{StrBuff} .= substr($sWk, 1);
        }
        else {
#print "CONT\n";
            my $iCnt1st = ord($sWk); # 1st byte of Continue may be a GR byte
            my($iStP, $iLenS) = @{$oBook->{_PrevInfo}};
            my $iLenB = length($oBook->{StrBuff});

        #1.1 Not in String
            if($iLenB >= ($iStP + $iLenS)) {
#print "NOT STR\n";
                $oBook->{StrBuff} .= $sWk;
#                $oBook->{StrBuff} .= substr($sWk, 1);
            }
        #1.2 Same code (Unicode or ASCII)
            elsif(($oBook->{_PrevCond} & 0x01) == ($iCnt1st & 0x01)) {
#print "SAME\n";
                $oBook->{StrBuff} .= substr($sWk, 1);
            }
            else {
        #1.3 Diff code (Unicode or ASCII)
                my $iDiff = ($iStP + $iLenS) - $iLenB;
                if($iCnt1st & 0x01) {
#print "DIFF ASC $iStP $iLenS $iLenB DIFF:$iDiff\n";
#print "BEF:", unpack("H6", $oBook->{StrBuff}), "\n";
                  my ($iDum, $iGr) =unpack('vc', $oBook->{StrBuff});
                  substr($oBook->{StrBuff}, 2, 1) = pack('c', $iGr | 0x01);
#print "AFT:", unpack("H6", $oBook->{StrBuff}), "\n";
                    for(my $i = ($iLenB-$iStP); $i >=1; $i--) {
                        substr($oBook->{StrBuff}, $iStP+$i, 0) =  "\x00"; 
                    }
                }
                else {
#print "DIFF UNI:", $oBook->{_PrevCond}, ":", $iCnt1st, " DIFF:$iDiff\n";
                    for(my $i = ($iDiff/2); $i>=1;$i--) {
                        substr($sWk, $i+1, 0) =  "\x00";
                    }
                }
                $oBook->{StrBuff} .= substr($sWk, 1);
           }
        }
    }
    else {
    #2. Saisho
        $oBook->{StrBuff} .= $sWk;
    }
#print " AFT2:", unpack("H60", $oBook->{StrBuff}), "\n";

    $oBook->{_PrevCond} = undef;
    $oBook->{_PrevInfo} = undef;

    while(length($oBook->{StrBuff}) >= 4) {
        my ( $raBuff, $iLen, $iStPos, $iLenS) = _convBIFF8String($oBook, $oBook->{StrBuff}, 1);
                                                    #No Code Convert
        if(defined($raBuff->[0])) {
            push @{$oBook->{PkgStr}}, 
                {
                    Text    => $raBuff->[0],
                    Unicode => $raBuff->[1],
                    Rich    => $raBuff->[2],
                    Ext     => $raBuff->[3],
            };
            $oBook->{StrBuff} = substr($oBook->{StrBuff}, $iLen);
        }
        else {
            $oBook->{_PrevCond} = $raBuff->[1];
            $oBook->{_PrevInfo} = [$iStPos, $iLenS];
            last;
        }
    }
}
#------------------------------------------------------------------------------
# _SwapForUnicode (for Spreadsheet::ParseExcel2)
#------------------------------------------------------------------------------
sub _SwapForUnicode(\$) 
{
    my($sObj) = @_;
#    for(my $i = 0; $i<length($$sObj); $i+=2){
    for(my $i = 0; $i<(int (length($$sObj) / 2) * 2); $i+=2) {
            my $sIt = substr($$sObj, $i, 1);
            substr($$sObj, $i, 1) = substr($$sObj, $i+1, 1);
            substr($$sObj, $i+1, 1) = $sIt;
    }
}
#------------------------------------------------------------------------------
# _NewCell (for Spreadsheet::ParseExcel2)
#------------------------------------------------------------------------------
sub _NewCell($$$%) 
{
    my($oBook, $iR, $iC, %rhKey)=@_;

	debug("oBook->{_CurSheet}=$oBook->{_CurSheet}, iR=$iR, iC=$iC, rhKey{Kind}=$rhKey{Kind}, rhKey{Val}=$rhKey{Val}, rhKey{FormatNo}=$rhKey{FormatNo}, rhKey{Format}=$rhKey{Format}, rhKey{Numeric}=$rhKey{Numeric}, rhKey{Code}=$rhKey{Code}") if $VERBOSE_DEBUG;
    my($sWk, $iLen);
    return undef unless(defined $oBook->{_CurSheet});

    my $oCell = 
        Spreadsheet::ParseExcel2::Cell->new(
            Val     => $rhKey{Val},
            FormatNo=> $rhKey{FormatNo},
            Format  => $rhKey{Format},
            Code    => $rhKey{Code},
            Type    => $oBook->{FmtClass}->ChkType(
                            $rhKey{Numeric}, 
                            $rhKey{Format}->{FmtIdx}),
        );
    $oCell->{_Kind}  = $rhKey{Kind};
	if ($oCell->{_Kind} =~ /^Formula/) {
		$oCell->{Formula} = $oBook->{Formula};
	}
    $oCell->{_Value} = $oBook->{FmtClass}->ValFmt($oCell, $oBook);
    if($rhKey{Rich}) {
        my @aRich = ();
        my $sRich = $rhKey{Rich};
        for(my $iWk=0;$iWk<length($sRich); $iWk+=4) {
            my($iPos, $iFnt) = unpack('v2', substr($sRich, $iWk));
            push @aRich, [$iPos, $oBook->{Font}[$iFnt]];
        }
        $oCell->{Rich}   =  \@aRich;
    }

    if(defined $_CellHandler) {
        if(defined $_Object){
            no strict;
            ref($_CellHandler) eq "CODE" ? 
                    $_CellHandler->($_Object, $oBook, $oBook->{_CurSheet}, $iR, $iC, $oCell) :
                    $_CellHandler->callback($_Object, $oBook, $oBook->{_CurSheet}, $iR, $iC, $oCell);
        }
        else{
            $_CellHandler->($oBook, $oBook->{_CurSheet}, $iR, $iC, $oCell);
        }
    }
    unless($_NotSetCell) {
        $oBook->{Worksheet}[$oBook->{_CurSheet}]->{Cells}[$iR][$iC] 
            = $oCell;
    }
    return $oCell;
}
#------------------------------------------------------------------------------
# ColorIdxToRGB (for Spreadsheet::ParseExcel2)
#------------------------------------------------------------------------------
sub ColorIdxToRGB($$){
    my($sPkg, $iIdx) = @_;
    return ((defined $aColor[$iIdx])? $aColor[$iIdx] : $aColor[0]);
}
#------------------------------------------------------------------------------
# debug
#------------------------------------------------------------------------------
sub debug {
	my($message) = @_;

	my($package, $filename, $line, $subroutine, $has_args, $wantarray) = caller(1);
	my($my_package, @dummies) = caller(0);
	$subroutine =~ s/^${my_package}:://;
	my $debug_message = "DEBUG: $subroutine: $message";
	supportingFunctions::log($debug_message, 5);
}



package Spreadsheet::ParseExcel2::CondFmt;

my $DEBUG = 0;

#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $hash =
		{
			sWk => $_[0],
		};

	($hash->{num_cf_records}, $hash->{option_flags}, $hash->{all_first_row}, $hash->{all_last_row}, $hash->{all_first_col}, $hash->{all_last_col}, $hash->{list_size}) = unpack("v7", $hash->{sWk});
	#debug_hash('hash', $hash);

	my ($offset) = 14;
	my (@range_array);
	for my $i (1..$hash->{list_size}) {
		my %range;
		($range{first_row}, $range{last_row}, $range{first_col}, $range{last_col}) = unpack("v4", substr($hash->{sWk}, $offset));
		#debug("range{first_row}=$range{first_row}, range{last_row}=$range{last_row}, range{first_col}=$range{first_col}, range{last_col}=$range{last_col}");
		$offset += 8;
		push @range_array, \%range;
	}
	$hash->{ranges} = \@range_array;

	return bless $hash, $class;
}

sub add_cf {
	my $moi = shift;
	my $cf = shift;
	push @{$moi->{cfs}}, $cf;
	debug(sprintf("New CFs length=%d after adding cf=0x%s", scalar(@{$moi->{cfs}}), unpack('H*', $cf)));
}

sub generate_binary {
	my $moi = shift;

	my $buffer = pack("v7", $moi->{num_cf_records}, $moi->{option_flags}, $moi->{all_first_row}, $moi->{all_last_row}, $moi->{all_first_col}, $moi->{all_last_col}, $moi->{list_size});
	foreach my $range (@{$moi->{ranges}}) {
		$buffer .= pack("v4", $$range{first_row}, $$range{last_row}, $$range{first_col}, $$range{last_col});
	}
	#debug(sprintf('buffer=0x%s', unpack("H*", $buffer))) if $COND_FMT_DEBUG;

	return $buffer;
}

sub increment_row_count {
	my $moi = shift;
	my $new_row_count = shift || 0;

	my $old_last_row = $moi->{all_last_row};
	$moi->{all_last_row} += $new_row_count;
	#debug("Incremented old row count of $old_last_row by $new_row_count to $moi->{all_last_row}") if $COND_FMT_DEBUG;
	foreach my $range_ref (@{$moi->{ranges}}) {
		if ($range_ref->{last_row} == $old_last_row) {
			#debug("Incrementing range last_row of $range_ref->{last_row} by $new_row_count") if $COND_FMT_DEBUG;
			$range_ref->{last_row} += $new_row_count;
			#debug("After increment, range_ref->{last_row}=$range_ref->{last_row}") if $COND_FMT_DEBUG;
		}
	}
}

sub debug_hash {
	my ($hash_name, $hash_ptr) = @_;

	my $output = "";
	while (my ($key, $value) = each %$hash_ptr) {
		$output .= $hash_name . '{' . $key . '}=' . $value . ' ';
	}
	debug($output, 1);
}

sub debug {
	return unless $DEBUG;
	my $message			= shift;
	my $indirect_call	= shift;
	my $subs_on_stack	= 1;
	$subs_on_stack++ if $indirect_call;

	my($package, $filename, $line, $subroutine, $has_args, $wantarray) = caller($subs_on_stack);
	my($my_package, @dummies) = caller(0);
	$subroutine =~ s/^${my_package}:://;
	my $debug_message = "DEBUG: $subroutine: $message";
	supportingFunctions::log($debug_message, 5);
}
1;
__END__

=head1 NAME

Spreadsheet::ParseExcel2 - Get information from Excel file

=head1 SYNOPSIS

    use strict;
    use Spreadsheet::ParseExcel2;
    my $oExcel = new Spreadsheet::ParseExcel2;

    #1.1 Normal Excel97
    my $oBook = $oExcel->Parse('Excel/Test97.xls');
    my($iR, $iC, $oWkS, $oWkC);
    print "FILE  :", $oBook->{File} , "\n";
    print "COUNT :", $oBook->{SheetCount} , "\n";
    print "AUTHOR:", $oBook->{Author} , "\n";
    for(my $iSheet=0; $iSheet < $oBook->{SheetCount} ; $iSheet++) {
        $oWkS = $oBook->{Worksheet}[$iSheet];
        print "--------- SHEET:", $oWkS->{Name}, "\n";
        for(my $iR = $oWkS->{MinRow} ; 
                defined $oWkS->{MaxRow} && $iR <= $oWkS->{MaxRow} ; $iR++) {
            for(my $iC = $oWkS->{MinCol} ;
                            defined $oWkS->{MaxCol} && $iC <= $oWkS->{MaxCol} ; $iC++) {
                $oWkC = $oWkS->{Cells}[$iR][$iC];
                print "( $iR , $iC ) =>", $oWkC->Value, "\n" if($oWkC);  # Formatted Value
                print "( $iR , $iC ) =>", $oWkC->{Val}, "\n" if($oWkC);  # Original Value
            }
        }
    }

I<new interface>

    use strict;
    use Spreadsheet::ParseExcel2;
    my $oBook = 
        Spreadsheet::ParseExcel2::Workbook->Parse('Excel/Test97.xls');
    my($iR, $iC, $oWkS, $oWkC);
    foreach my $oWkS (@{$oBook->{Worksheet}}) {
        print "--------- SHEET:", $oWkS->{Name}, "\n";
        for(my $iR = $oWkS->{MinRow} ; 
                defined $oWkS->{MaxRow} && $iR <= $oWkS->{MaxRow} ; $iR++) {
            for(my $iC = $oWkS->{MinCol} ;
                            defined $oWkS->{MaxCol} && $iC <= $oWkS->{MaxCol} ; $iC++) {
                $oWkC = $oWkS->{Cells}[$iR][$iC];
                print "( $iR , $iC ) =>", $oWkC->Value, "\n" if($oWkC);
            }
        }
    }

=head1 DESCRIPTION

Spreadsheet::ParseExcel2 makes you to get information from Excel95, Excel97, Excel2000 file.

=head2 Functions

=over 4

=item new

I<$oExcel> = new Spreadsheet::ParseExcel2(
                    [ I<CellHandler> => \&subCellHandler, 
                      I<NotSetCell> => undef | 1,
                    ]);

Constructor.


=over 4

=item CellHandler I<(experimental)>

specify callback function when a cell is detected.

I<subCellHandler> gets arguments like below:

sub subCellHandler (I<$oBook>, I<$iSheet>, I<$iRow>, I<$iCol>, I<$oCell>);

B<CAUTION> : The atributes of Workbook may not be complete.
This function will be called almost order by rows and columns.
Take care B<almost>, I<not perfectly>.

=item NotSetCell I<(experimental)>

specify set or not cell values to Workbook object.

=back

=item Parse

I<$oWorkbook> = $oParse->Parse(I<$sFileName> [, I<$oFmt>]);

return L<"Workbook"> object.
if error occurs, returns undef.

=over 4

=item I<$sFileName>

name of the file to parse

From 0.12 (with OLE::Storage_Lite v.0.06), 
scalar reference of file contents (ex. \$sBuff) or 
IO::Handle object (inclucdng IO::File etc.) are also available.

=item I<$oFmt>

L<"Formatter Class"> to format the value of cells.

=back

=item ColorIdxToRGB

I<$sRGB> = $oParse->ColorIdxToRGB(I<$iColorIdx>);

I<ColorIdxToRGB> returns RGB string corresponding to specified color index.
RGB string has 6 charcters, representing RGB hex value. (ex. red = 'FF0000')

=back

=head2 Workbook

I<Spreadsheet::ParseExcel2::Workbook>

Workbook class has these methods :

=over 4

=item Parse

(class method) : same as Spreadsheet::ParseExcel2

=back

=over 4

=item Worksheet

I<$oWorksheet> = $oBook->Worksheet(I<$sName>);

I<Worksheet> returns a Worksheet object with I<$sName> or undef.
If there is no worksheet with I<$sName> and I<$sName> contains only digits,
it returns a Worksheet object at that position.

=back

Workbook class has these properties :

=over 4

=item File

Name of the file

=item Author

Author of the file

=item Flag1904

If this flag is on, date of the file count from 1904.

=item Version

Version of the file

=item SheetCount

Numbers of L<"Worksheet"> s in that Workbook

=item Worksheet[SheetNo]

Array of L<"Worksheet">s class

=item PrintArea[SheetNo]

Array of PrintArea array refs.

Each PrintArea is : [ I<StartRow>, I<StartColumn>, I<EndRow>, I<EndColumn>]

=item PrintTitle[SheetNo]

Array of PrintTitle hash refs.

Each PrintTitle is : 
        { Row => [I<StartRow>, I<EndRow>], 
          Column => [I<StartColumn>, I<EndColumn>]}

=back

=head2 Worksheet

I<Spreadsheet::ParseExcel2::Worksheet>

Worksheet class has these methods:

=over 4

=item Cell ( ROW, COL )

Return the Cell iobject at row ROW and column COL if
it is defined. Otherwise return undef.

=item RowRange ()

Return a two-element list (MIN, MAX) containing the
minimum and maximum of defined rows in the worksheet
If there is no row defined MAX is smaller than MIN.

=item ColRange ()

Return a two-element list (MIN, MAX) containing the
minimum and maximum of defined columns in the worksheet
If there is no row defined MAX is smaller than MIN.

=back

Worksheet class has these properties:

=over 4

=item Name

Name of that Worksheet

=item DefRowHeight

Default height of rows

=item DefColWidth

Default width of columns

=item RowHeight[Row]

Array of row height

=item ColWidth[Col]

Array of column width (undef means DefColWidth)

=item Cells[Row][Col]

Array of L<"Cell">s infomation in the worksheet

=item Landscape

Print in horizontal(0) or vertical (1).

=item Scale

Print scale.

=item FitWidth

Number of pages with fit in width. 

=item FitHeight

Number of pages with fit in height.

=item PageFit

Print with fit (or not).

=item PaperSize

Papar size. The value is like below:

  Letter               1, LetterSmall          2, Tabloid              3 ,
  Ledger               4, Legal                5, Statement            6 ,
  Executive            7, A3                   8, A4                   9 ,
  A4Small             10, A5                  11, B4                  12 ,
  B5                  13, Folio               14, Quarto              15 ,
  10x14               16, 11x17               17, Note                18 ,
  Envelope9           19, Envelope10          20, Envelope11          21 ,
  Envelope12          22, Envelope14          23, Csheet              24 ,
  Dsheet              25, Esheet              26, EnvelopeDL          27 ,
  EnvelopeC5          28, EnvelopeC3          29, EnvelopeC4          30 ,
  EnvelopeC6          31, EnvelopeC65         32, EnvelopeB4          33 ,
  EnvelopeB5          34, EnvelopeB6          35, EnvelopeItaly       36 ,
  EnvelopeMonarch     37, EnvelopePersonal    38, FanfoldUS           39 ,
  FanfoldStdGerman    40, FanfoldLegalGerman  41, User                256

=item PageStart

Start page number.

=item UsePage

Use own start page number (or not).

=item LeftMergin, RightMergin, TopMergin, BottomMergin, HeaderMergin, FooterMergin

Mergins for left, right, top, bottom, header and footer.

=item HCenter

Print in horizontal center (or not)

=item VCenter

Print in vertical center  (or not)

=item Header

Content of print header.
Please refer Excel Help.

=item Footer

Content of print footer.
Please refer Excel Help.

=item PrintGrid

Print with Gridlines (or not)

=item PrintHeaders

Print with headings (or not)

=item NoColor

Print in black-white (or not).

=item Draft

Print in draft mode (or not).

=item Notes

Print with notes (or not).

=item LeftToRight

Print left to right(0) or top to down(1).

=item HPageBreak

Array ref of horizontal page breaks.

=item VPageBreak

Array ref of vertical page breaks.

=item MergedArea

Array ref of merged areas.
Each merged area is : [ I<StartRow>, I<StartColumn>, I<EndRow>, I<EndColumn>]

=back

=head2 Cell

I<Spreadsheet::ParseExcel2::Cell>

Cell class has these properties:

=over 4

=item Value

I<Method>
Formatted value of that cell

=item Val

Original Value of that cell

=item Type

Kind of that cell ('Text', 'Numeric', 'Date')

=item Code

Character code of that cell (undef, 'ucs2', '_native_')
undef tells that cell seems to be ascii.
'_native_' tells that cell seems to be 'sjis' or something like that.

=item Format

L<"Format"> for that cell.

=item Merged

That cells is merged (or not).

=item Rich

Array ref of font informations about each characters.

Each entry has : [ I<Start Position>, I<Font Object>]

For more information please refer sample/dmpExR.pl

=back

=head2 Format

I<Spreadsheet::ParseExcel2::Format>

Format class has these properties:

=over 4

=item Font

L<"Font"> object for that Format.

=item AlignH

Horizontal Alignment.

  0: (standard), 1: left,       2: center,     3: right,      
  4: fill ,      5: justify,    7:equal_space  

B<Notice:> 6 may be I<merge> but it seems not to work.

=item AlignV

Vertical Alignment.

    0: top,  1: vcenter, 2: bottom, 3: vjustify, 4: vequal_space

=item Indent

Number of indent

=item Wrap

Wrap (or not).

=item Shrink

Display in shrinking (or not)

=item Rotate

In Excel97, 2000      : degrees of string rotation.
In Excel95 or earlier : 0: No rotation, 1: Top down, 2: 90 degrees anti-clockwise, 
                        3: 90 clockwise

=item JustLast

JustLast (or not).
I<I have never seen this attribute.>

=item ReadDir

Direction for read.

=item BdrStyle

Array ref of boder styles : [I<Left>, I<Right>, I<Top>, I<Bottom>]

=item BdrColor

Array ref of boder color indexes : [I<Left>, I<Right>, I<Top>, I<Bottom>]

=item BdrDiag

Array ref of diag boder kind, style and color index : [I<Kind>, I<Style>, I<Color>]
  Kind : 0: None, 1: Right-Down, 2:Right-Up, 3:Both

=item Fill

Array ref of fill pattern and color indexes : [I<Pattern>, I<Front Color>, I<Back Color>]

=item Lock

Locked (or not).

=item Hidden

Hiddedn (or not).

=item Style

Style format (or Cell format)

=back

=head2 Font

I<Spreadsheet::ParseExcel2::Font>

Format class has these properties:

=over 4

=item Name

Name of that font.

=item Bold

Bold (or not).

=item Italic

Italic (or not).

=item Height

Size (height) of that font.

=item Underline

Underline (or not).

=item UnderlineStyle

0: None, 1: Single, 2: Double, 0x21: Single(Account), 0x22: Double(Account)

=item Color

Color index for that font.

=item Strikeout

Strikeout (or not).

=item Super

0: None, 1: Upper, 2: Lower

=back

=head1 Formatter class

I<Spreadsheet::ParseExcel2::Fmt*>

Formatter class will convert cell data.

Spreadsheet::ParseExcel2 includes 2 formatter classes: FmtDefault and FmtJapanese. 
You can create your own FmtClass as you like.

Formatter class(Spreadsheet::ParseExcel2::Fmt*) should provide these functions:

=over 4

=item ChkType($oSelf, $iNumeric, $iFmtIdx)

tells type of the cell that has specified value.

=over 8

=item $oSelf

Formatter itself

=item $iNumeric

If on, the value seems to be number

=item $iFmtIdx

Format index number of that cell

=back

=item TextFmt($oSelf, $sText, $sCode)

converts original text into applicatable for Value.

=over 8

=item $oSelf

Formatter itself

=item $sText

Original text

=item $sCode

Character code of Original text

=back

=item ValFmt($oSelf, $oCell, $oBook) 

converts original value into applicatable for Value.

=over 8

=item $oSelf

Formatter itself

=item $oCell

Cell object

=item $oBook

Workbook object

=back

=item FmtString($oSelf, $oCell, $oBook)

get format string for the I<$oCell>.

=over 8

=item $oSelf

Formatter itself

=item $oCell

Cell object

=item $oBook

WorkBook object contains that cell

=back

=back

=head1 KNOWN PROBLEM

This module can not get the values of fomulas in 
Excel files made with Spreadsheet::WriteExcel.
Normaly (ie. By Excel application), formula has the result with it.
But Spreadsheet::WriteExcel writes formula with no result.
If you set your Excel application "Auto Calculation" off.
(maybe [Tool]-[Option]-[Calculation] or something)
You will see the same result.

=head1 AUTHOR

Kawai Takanori (Hippo2000) kwitknr@cpan.org

    http://member.nifty.ne.jp/hippo2000/            (Japanese)
    http://member.nifty.ne.jp/hippo2000/index_e.htm (English)

=head1 SEE ALSO

XLHTML, OLE::Storage, Spreadsheet::WriteExcel, OLE::Storage_Lite

This module is based on herbert within OLE::Storage and XLHTML.

=head1 TODO

- Spreadsheet::ParseExcel2 : 
 Password protected data, Formulas support, HyperLink support, 
 Named Range support

- Spreadsheet::ParseExcel2::SaveParser :
 Catch up Spreadsheet::WriteExce feature, Create new Excel fle

=head1 COPYRIGHT

Copyright (c) 2000-2004 Kawai Takanori
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 ACKNOWLEDGEMENTS

First of all, I would like to acknowledge valuable program and modules :
XHTML, OLE::Storage and Spreadsheet::WriteExcel.

In no particular order: Yamaji Haruna, Simamoto Takesi, Noguchi Harumi, 
Ikezawa Kazuhiro, Suwazono Shugo, Hirofumi Morisada, Michael Edwards, Kim Namusk 
and many many people + Kawai Mikako.

=cut
