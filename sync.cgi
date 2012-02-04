#!/usr/bin/perl
################################################################################
#
#	TODO
#
#	- Make 'DB overrides sheet UPDATEs' configurable
#	- Flesh out spec file for "Issues & Questions"  workbook
#	- Test: {update_precedence} configuration parameter
#	- Test: multiple field spreadsheet field updates by concatenating them
#	- Perl POD
#
#	DONE
#
#	- Added spec name to log
#	- Made project lookup sheet specific
#	- Detect when spec has sheet that's not in the workbook
#	- Clean up spec (no workbook level info any longer)
#	- Made 'DB source of only INSERTs' configurable
#	- Handle multiple field spreadsheet field updates by concatenating them
#
#	BUGS
#
#	- Format of cell doesn't carry over if the cell is Empty
#	- Unicode font names don't carry over - but unicode cell text works okay
#	- Writing formulas causes "Malformed UTF-8 character" errors, but data okay
#
#	LIMITATIONS
#
#	The following is a list of limitations of this program,
#	due to the Spreadsheet modules used.
#
#	Formulas are handled, with the following exception(s):
#	- IF function is readable, but it generates a 'WideChar' error and corrupts the output file if writing it back out is attempted, so we skip writing it.
#
#	The following workbook properties can't be duplicated:
#	- Author      # Readable, but not writeable
#	- Version     # Readable, but not writeable
#	
#	The following spreadsheet properties can't be duplicated:
#	- Print info: title, header/footer, etc., however, print area does work
#
#	The following cell properties can't be duplicated:
#	- Font Outline: Readable, but not writeable
#	- Font Shadow: Readable, but not writeable
#	- Font Super/Subscript: Coded according to the docs, but it doesn't work
#	- Numeric Format: Only works on dates
#	- Center Across: Writeable, but not readable
#	- Borders: If there's data, then it's somewhat off.  If no data, no border
#
################################################################################
#
#	Configuration
#
use strict;
#
use lib "./lib";
#
use CGI;
use MIME::Base64;
use TraqConfig;
use supportingFunctions;
use Data::Dumper;
use DataProc qw(&Process);
use dbFunctions;
use Encode;
use Spreadsheet::ParseExcel2;
use Spreadsheet::ParseExcel::FmtJapan;
use Spreadsheet::WriteExcel;
use Tie::RefHash;
use Unicode::String;
#JJT	use encoding 'utf8';
#
#	Project Traq Configuration hash
#
use vars qw(%c);
*c = \%TraqConfig::c;
#
#	Specification file's spec hash
#
use vars qw(%spec);
#
#	Global Constants
#
my $DEBUG			= 0;
my $VERBOSE_DEBUG	= 0;
my $TEMP_WORKBOOK_FILE_NAME	= '/tmp/sync-workbook.xls';
my $USER_LOG_DELIMITER	= 'USER-LOG-DELIMITER';
my $LOGGING			= 5;
my $STANDALONE		= $#ARGV;
my $HOME_DIR		= $TraqConfig::c{dir}{home};
my $SPEC_DIR		= $HOME_DIR . 'spec';
my $OUTPUT_DIR		= '/tmp/';
#
my $ENCODING = "";	# Valid values are "euc", "sjis", "jis"
#JJT	my $ENCODING = "jis";	# Valid values are "euc", "sjis", "jis"
my $DATE_FORMAT_STRING = 'm/d/yy';
my $WORK_ON_UNICODE_FONT_NAME = 0;
my(@HORIZONTAL_ALIGNMENT_MAP) = (
	"dummy0",
	"left",
	"center",
	"right",
	"fill",
	"justify",
	"dummy6",
	"center_across"
);
my(@VERTICAL_ALIGNMENT_MAP) = (
	"top",
	"vcenter",
	"bottom",
	"vjustify"
);
#
#	Global, main package variables
#
my $outputFormatter;
my %output_format_props;
tie %output_format_props, "Tie::RefHash";
my $flag_1904;
my $date_format;
#
#	Begin logging (system and user)
#
startLog();
my $start_timestamp = get_now_from_db();
user_log_delimiter();
#
#	CGI work
#
my $html;
my $cgi = new CGI;
my $debug = 0 || $cgi->param('debug') || $cgi->param('DEBUG') || $VERBOSE_DEBUG;
my $user_id = getUserId($cgi);
my $mode = uc($cgi->param('mode')) || 'DISPLAY';
debug_query_parms();
$mode = 'IMPORT'	if ($cgi->param('import'));
$mode = 'EXPORT'	if ($cgi->param('export'));
$mode = 'LOG'		if ($cgi->param('log'));
verbose_debug("mode=$mode");
my $dry_run = $cgi->param('dry_run');
#
#	Branch based on mode
#
if ($mode eq 'UPLOAD') {
	upload_and_sync();
	view_log();
} elsif ($mode eq 'DISPLAY') {
	display();
} elsif ($mode eq 'LOG') {
	view_todays_log();
} elsif ($mode eq 'EXPORT') {
	download_latest_workbook();
} elsif ($mode eq 'IMPORT') {
	upload_workbook_into_db();
	view_log();
} else {
	unknown_mode();
}
#
#	We're done
#
exit();
#
#	Display
#
sub display {
	user_log("Display Sync page");

	#	Generate HTML Header
	my $html = '';
	$html .= $cgi->header();
	$html .= getHeader($user_id, 'traq');

    opendir(SPEC_DIR, $SPEC_DIR) or fatal_error("Can't opendir $SPEC_DIR: $!");
	my $file;
    my @specs;
    while (defined($file = readdir(SPEC_DIR))) {
        push(@specs, $file) if $file =~ /\w+\.spec/;
    }
    closedir(SPEC_DIR);

	my %template_hash;
    $template_hash{SPEC_OPTIONLIST}[0] = &makeOptionList(\@specs,\@specs);
    $html .= Process(\%template_hash, "$c{dir}{generaltemplates}/sync.tmpl");

	#	Generate HTML Footer
	$html .= getFooter($user_id, 'traq');

	#	Output the HTML
	print $html;
}
#
#	Debug the query parameters
#
sub debug_query_parms {
	#	Generate a list of query parameters and their values
	my @query_parms = $cgi->param;
	debug("CGI Query Parms are as follows:") if $VERBOSE_DEBUG;
	foreach my $query_parm (@query_parms) {
		my $value = $cgi->param($query_parm);
		debug("$query_parm=$value") if $VERBOSE_DEBUG;
	}
	debug() if $VERBOSE_DEBUG;
}
#
#	View today's log
#
sub view_todays_log {
	view_log('CURDATE()');
}
#
#	View a subset of the user's log based on input start datetimestamp
#
sub view_log {
	my $cutoff_date = shift || "'$start_timestamp'";
	debug("cutoff_date=$cutoff_date") if $DEBUG;

	#	Generate HTML Header
	$html = $cgi->header();
	$html .= getHeader($user_id, 'traq');

	#	Do the SQL to get today's user log entries
	my $sql = "SELECT insert_ts, spec_name, entry FROM traq_workbook_logs WHERE insert_ts >= $cutoff_date ORDER BY serial";
	debug("sql=$sql") if $DEBUG;
	my %sql_results = doSql($sql);

	#	Generate the hash of user log entries
	my %template_hash;
	my $row_count = exists $sql_results{insert_ts} ? scalar(@{$sql_results{insert_ts}}) : 0;
	debug("row_count=$row_count") if $DEBUG;
	for (my $i = 0; $i < $row_count; $i++) {
    	$template_hash{LOG_TIMESTAMP}	[$i] = $sql_results{insert_ts}[$i];
    	$template_hash{LOG_SPEC_FILE}	[$i] = $sql_results{spec_name}[$i];
    	$template_hash{LOG_ENTRY}		[$i] = ($sql_results{entry}[$i] eq $USER_LOG_DELIMITER) ? '<HR>' : $sql_results{entry}[$i];
	}
    $html .= Process(\%template_hash, "$c{dir}{generaltemplates}/sync-log.tmpl");

	#	Generate HTML Footer
	$html .= getFooter($user_id, 'traq');

	#	Output the HTML
	print $html;
}
#
#	Upload new Excel workbook and synchronize it with the DB
#
sub upload_and_sync {
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	#	Get the file names: input and spec
	my $input_file_name = $cgi->param('input_file');
	debug("input_file_name=$input_file_name") if $sub_debug;
	fatal_error("No input file given") unless ($input_file_name);
	my $short_spec = $cgi->param('spec_file');
	debug("short_spec=$short_spec") if $sub_debug;
	fatal_error("No specification file given") unless ($short_spec);

	user_log("Upload and Synchronize", $short_spec);

	#	Start user logging
	user_log('Start', $short_spec);
	user_log("This is a Dry Run - No Updates will be Applied", $short_spec) if $dry_run;

	#	Upload the Excel Workbook and store it in the DB
	my $current_book_data_ptr = upload_file($input_file_name);

	#	Process the Specification File
	my $long_spec = "$SPEC_DIR/$short_spec";
	debug("short_spec=$short_spec, long_spec=$long_spec") if $sub_debug;
	unless (defined(do $long_spec)) {
		fatal_error("Unable to parse spec. file $long_spec: $@") if $@;
		fatal_error("Unable to read spec. file $long_spec: $!") if $!;
	}

	#	Get the Previous Workbook from the DB
	my($previous_book_data_ptr, $last_date) = get_latest_workbook_from_db();
	fatal_error("There's no Previous Workbook in the database") unless ($previous_book_data_ptr);

	#	Store the New Uploaded Workbook in the DB
	store_workbook_in_db($input_file_name, $current_book_data_ptr) unless ($dry_run);

	#	Parse the Previous and Current Versions of the Workbook
	my $previous_output_workbook;
	debug('Parsing the previous workbook...') if $sub_debug;
	$previous_output_workbook = $previous_book_data_ptr ? parse_input_workbook($previous_book_data_ptr, $short_spec) : undef;
	debug("previous_output_workbook=$previous_output_workbook") if $sub_debug;
	debug('Parsing the current workbook...') if $sub_debug;
	my $current_input_workbook = parse_input_workbook($current_book_data_ptr, $short_spec);
	debug("current_input_workbook=$current_input_workbook") if $sub_debug;
	validate_workbook_sheets_against_spec($current_input_workbook);

	#	Diff the Current Input Workbook with the Previous Output Version
	diff_workbooks($previous_output_workbook, $current_input_workbook, $short_spec);

	#	Generate the New Output Workbook and Store it in the DB
	unless ($dry_run) {
		my $new_workbook_contents_ptr = write_workbook($current_input_workbook, $last_date, $short_spec);
		store_workbook_in_db('<sync.cgi>', $new_workbook_contents_ptr);
	}

	user_log('Finish', $short_spec);

	return $short_spec;
}
#
#	Confirm that all the sheets in the spec are in the workbook
#
sub validate_workbook_sheets_against_spec {
	my ($workbook) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	# Build an array of sheet names in this workbook
	my @sheet_names;
	foreach my $worksheet (@{$workbook->{Worksheet}}) {
		my $sheet_name = $worksheet->{Name};
		push @sheet_names, $sheet_name;
	}
	debug("sheet_names=@sheet_names") if $sub_debug;

	# Ensure that our spec sheet names are in the workbook
	foreach my $spec_sheet_name (keys %{$spec{sheet}}) {
		debug("Validating sheet $spec_sheet_name") if $sub_debug;
		my $found = grep(/^$spec_sheet_name$/, @sheet_names);
		debug("found=$found") if $sub_debug;
		fatal_error("There's a specification for sheet '$spec_sheet_name', but that sheet is not in the workbook") unless $found;
	}
}
#
#	Generate the download file name based on the specification file name
#
sub generate_download_file_name {
	my $spec = $cgi->param('spec_file');
	my $download_file_name = $spec;
	$download_file_name =~ s/\.spec$//;
	$download_file_name = "$download_file_name-workbook.xls";
	verbose_debug("spec=$spec, download_file_name=$download_file_name");

	return $download_file_name;
}
#
#	Upload a file
#
sub upload_file {
	my $file_name = shift;
	$file_name =~ s/.*[\/\\](.*)/$1/;	# Trim path from file name
	local $/;
	my $file_data = <$file_name>;

	return \$file_data;
}
#
#	Download a file to the user via CGI
#
sub download_file {
	my $output_file_name = generate_download_file_name();
	verbose_debug("output_file_name=$output_file_name");
	fatal_error("No output file specified") unless ($output_file_name);
	my $data_ptr = shift || fatal_error("No data pointed to by argument to download_file");

	#	Here's the "meat" - we download the file here
	print "Content-Type: application/x-download\n";
	print "Content-Disposition:attachment;filename=$output_file_name\n\n";
	print $$data_ptr;

	return $output_file_name;
}
#
#	Unknown run mode
#
sub unknown_mode {
	fatal_error("Unknown run mode of $mode");
}
#
#	Create the formatter
#
sub create_input_formatter {
	if ($ENCODING) {
		$outputFormatter = Spreadsheet::ParseExcel::FmtJapan->new(Code => $ENCODING);
	} else {
		$outputFormatter = Spreadsheet::ParseExcel::FmtDefault->new();
	}
}
#
#	Parse the input workbook file
#
sub parse_input_workbook {
	my($input_book_data_ptr, $spec) = @_;
	#
	#	Parse the Input Excel Workbook
	#
	create_input_formatter();
	my($input_workbook) = Spreadsheet::ParseExcel2::Workbook->Parse($input_book_data_ptr, $outputFormatter);
	#
	#	Map the spreadsheet fields to table columns
	#
	foreach my $input_worksheet (@{$input_workbook->{Worksheet}}) {
		map_sheet_cells_to_db_fields($input_worksheet, $spec);
	}
	#
	return $input_workbook;
}
#
#	Map the cells of a worksheet to DB table fields
#
sub map_sheet_cells_to_db_fields {
	my($input_worksheet, $spec) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;
	#
	my $sheet_name = $input_worksheet->{Name};
	debug("sheet_name=$sheet_name") if $sub_debug;
	#
	unless (exists $spec{sheet}{$sheet_name}) {
		if ($sub_debug) {
			debug("We're skipping $sheet_name because it has no spec");
			debug();
		}
		return;
	}
	#
	my %sheet_spec = %{$spec{sheet}{$sheet_name}};
	my %column_spec;
	%column_spec = %{$sheet_spec{column}} if exists $sheet_spec{column};
	debug("column_spec=" . hash_to_string(\%column_spec)) if $sub_debug && exists $sheet_spec{column};
	#
	#	Get the Range of Row and Column Indexes
	#
	my($min_row, $max_row) = $input_worksheet->RowRange();
	debug("\tmin_row=$min_row, max_row=$max_row") if $sub_debug;
	my($min_col, $max_col) = $input_worksheet->ColRange();
	debug("\tmin_col=$min_col, max_col=$max_col") if $sub_debug;
	#
	#	Outer Row Loop
	#
	my $first_data_row = exists $sheet_spec{first_data_row} ? $sheet_spec{first_data_row} - 1 : 0;
	for (my $row_index = $min_row; $row_index <= $max_row; $row_index++) {
		if ($row_index < $first_data_row) {
			debug("Skipping Row $row_index because it's before the data") if $sub_debug;
			next;
		}
		#
		#	Inner Cell Loop
		#
		my %sheet_db_row;
		for (my $col_index = $min_col; $col_index <= $max_col; $col_index++) {
			my $cell = $input_worksheet->{Cells}[$row_index][$col_index];
			$cell->{db_field} = $column_spec{map_0based_col_index_to_alpha26($col_index)} if %column_spec;
			if ($cell->{db_field}) {
				my $db_field = $cell->{db_field};
				$sheet_db_row{data}{$db_field}{value} = $cell->{Val};
				debug("row_index=$row_index, col_index=$col_index, cell->{Val}=\"$cell->{Val}\"\, cell->{Type}=$cell->{Type}, cell->{db_field}=$cell->{db_field}, sheet_db_row{data}{$db_field}{value}=$sheet_db_row{data}{$db_field}{value}") if $sub_debug;
			}	# If
		}	# Column
		#	Store the Row of DB data in the worksheet object
		if (exists $sheet_db_row{data}{record_id}) {
			$sheet_db_row{_sheet_row_index} = $row_index;
			my $record_id = $sheet_db_row{data}{record_id}{value};
			if ($record_id) {
				$input_worksheet->{db_data}{$record_id} = \%sheet_db_row;
				debug("There's a record_id of $record_id, so we put this row into db_data") if $sub_debug;
			} else {
				fatal_error("There IS a Key in row $row_index, BUT there's NOT");
			}
		} else {
			error("There's NO record_id field in row $row_index, so we can't store this worksheet DB data", $spec);
		}
	}	# Row
	debug() if $sub_debug;

	if ($sub_debug) {
		debug("sheet_db_data after we loaded the spreadsheet");
		debug_sheet_db_data($input_worksheet);
		debug();
	}
}
#
#	Take a 0-based base-10 column number and return an ALPHA-26 string
#
sub map_0based_col_index_to_alpha26($) {
	my($col) = @_;

	my($modulo) = $col % 26;
	my($divide) = int($col / 26);

	my($small) = chr(ord('A') + $modulo);
	my($big) = chr(ord('A') + $divide - 1);

	my $result = $divide == 0 ? $small : "$big$small";
	verbose_debug("col=$col, result=$result");

	return $result;
}
#
#	Map an Alpha26 Cell Notation Column Name to a 0-Based Index
#
sub map_alpha26_to_0based_col_index {
	my($column_name) = uc($_[0]);

	if (length($column_name) == 1) {
		return (ord($column_name) - ord('A'));
	} elsif (length($column_name) == 2) {
		my($first_char, $second_char) = $column_name =~ /^(.)(.)$/;
		my $first_value = ord($first_char) - ord('A');
		my $second_value = ord($second_char) - ord('A');
		return ($first_value + 1) * 26 + $second_value;
	} else {
		fatal_error("column_name is more than 2 characters long: $column_name");
	}
}
#
#	Generate the Output Excel Workbook
#
sub write_workbook {
	my($input_workbook, $last_date, $spec) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;
	debug("last_date=$last_date") if $sub_debug;
	#
	#	Write the Output Excel Workbook
	#
	my $sheetCount = $input_workbook->{SheetCount};
	my $output_workbook;
	unless ($dry_run) {
		$output_workbook = Spreadsheet::WriteExcel->new($TEMP_WORKBOOK_FILE_NAME);
		fatal_error("Unable to create new Excel file '$TEMP_WORKBOOK_FILE_NAME'") unless defined($output_workbook);
	}
	#
	#	Duplicate the 1904 flag
	#
	my($flag_1904) = $input_workbook->{Flag1904};
	debug("flag_1904=$flag_1904") if $sub_debug;
	$output_workbook->set_1904($flag_1904) unless ($dry_run);
	#
	#	Sync the Database with the Worksheets
	#
	my $sheet_index = 0;
	foreach my $input_worksheet (@{$input_workbook->{Worksheet}}) {
		my $sheet_name = $input_worksheet->{Name};
		my %sql_results = read_db_data($sheet_name, $last_date);
		my $new_row_count = sync_db_with_worksheet($input_worksheet, $spec, %sql_results);
		write_sheet($input_workbook, $input_worksheet, $output_workbook, $sheet_index, $new_row_count, $spec) unless ($dry_run);
		$sheet_index++;
	}	# Spreadsheet Loop
	#
	#	Clean Up
	#
	unless ($dry_run) {
		$output_workbook->close() || fatal_error("Unable to close out file '$TEMP_WORKBOOK_FILE_NAME'");
		debug_output_formats() if $VERBOSE_DEBUG;
		return get_file_contents($TEMP_WORKBOOK_FILE_NAME);
	}
	return undef;
}
#
#	Sync the Database with the Worksheeet
#
sub sync_db_with_worksheet {
	my($worksheet, $spec, %sql_results) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	my $worksheet_name = $worksheet->{Name};
	debug("worksheet=$worksheet->{Name}") if $sub_debug;
	user_log("Synchronizing DB with sheet $worksheet_name...", $spec);

	#	Debug the Spreadsheet data
	my $spreadsheet_row_count = scalar(keys %{$worksheet->{db_data}});
	debug_sheet_db_data($worksheet) if $sub_debug;

	#	Debug the DB data
	my $db_row_count = $sql_results{record_id} ? scalar(@{$sql_results{record_id}}) : 0;
	debug_db_data(%sql_results) if $sub_debug && $VERBOSE_DEBUG;

	#	Update the Workbook with New and Updated Database data
	my %new_db_data;
	my %modified_db_data;
	my $new_row_count = 0;
	if ($db_row_count) {
		%new_db_data = filter_activity(1, %sql_results);
		$new_row_count = add_new_db_rows_to_sheet($worksheet, $spec, %new_db_data);

		%modified_db_data = filter_activity(undef, %sql_results);
		update_sheet_with_modified_db_data($worksheet, $spec, %modified_db_data);
	} else {
		debug("No Activity was returned from the DB, so no filtering is needed") if $sub_debug;
	}

	update_db_with_sheet_mods($worksheet, $spec, %modified_db_data);
	return $new_row_count;
}
#
#	Add New Rows to the Spreadsheet from the DB
#
sub add_new_db_rows_to_sheet {
	my($worksheet, $spec, %new_db_data) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	if ($sub_debug) {
		debug("Here's the NEW db activity data");
		debug_filtered_activity_data(%new_db_data);
	}

	my $row_count = scalar(keys %new_db_data);
	if ($row_count == 0) {
		debug("There is NO New DB data") if $sub_debug;
		return;
	}

	my($min_row, $max_row) = $worksheet->RowRange();
	my($min_col, $max_col) = $worksheet->ColRange();
	my $new_row_index = $max_row + 1;
	debug("min_row=$min_row, max_row=$max_row, min_col=$min_col, max_col=$max_col, new_row_index=$new_row_index") if $sub_debug;
	my %sheet_spec = %{$spec{sheet}{$worksheet->{Name}}};
	my $project_id = $sheet_spec{project_id};
	debug("project_id=$project_id") if $sub_debug;
	fatal_error("Project ID Not defined for sheet '$worksheet->{Name}'", $spec) unless $project_id;
	my %column_spec;
	%column_spec = %{$sheet_spec{column}} if exists $sheet_spec{column};
	debug("column_spec=" . hash_to_string(\%column_spec)) if $sub_debug && exists $sheet_spec{column};

	my $new_rows = 0;
	debug("$row_count rows of New DB Data to Add to sheet $worksheet->{Name} starting at Row " . ($new_row_index+1)) if $sub_debug;
	foreach my $record_id (sort {$a <=> $b} keys %new_db_data) {
		debug("Adding Row " . ($new_row_index+1) . " to Spreadsheet with record_id of $record_id") if $sub_debug;
		my %db_row = db_GetRecord($record_id);
		debug("Got row for record_id=$record_id from DB: " . hash_to_string(\%db_row)) if $sub_debug;
		for (my $column_index = $min_col; $column_index <= $max_col; $column_index++) {
			my $db_field = $column_spec{map_0based_col_index_to_alpha26($column_index)} if %column_spec;
			if ($db_field) {
				my $db_field_value = $db_row{$db_field};
				my $display_value = ($db_field eq 'record_id') ? $record_id : getDisplayValue($db_field_value, $db_field, $db_row{type}, $project_id, $user_id);
        		my $cell_above = $worksheet->{Cells}[$new_row_index-1][$column_index];
				debug("new_row_index=$new_row_index, column_index=$column_index, cell_above->{Type}=$cell_above->{Type}, cell_above->{Format}=$cell_above->{Format}, db_field=$db_field, db_field_value=$db_field_value, display_value=$display_value") if $sub_debug;
				my $new_cell = Spreadsheet::ParseExcel2::Cell->new(
            			Val     => $display_value,
						Type	=> $cell_above->{Type},
						Format	=> $cell_above->{Format},
        			);
        		$worksheet->{Cells}[$new_row_index][$column_index] = $new_cell;
			}	# If
		}	# Column
    	$worksheet->{MaxRow} = $new_row_index++; 
		++$new_rows;
	}	# Row
	my $prefix = $dry_run ? "If this had not been a Dry Run, then it would have created" : "Created";
	user_log("$prefix $new_rows new rows on sheet $worksheet->{Name} from the database", $spec);
	return $new_rows;
}
#
#	Update Spreadsheet with Modified Rows from the DB
#
sub update_sheet_with_modified_db_data {
	my($worksheet, $spec, %modified_db_data) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	if ($sub_debug) {
		debug("Here's the MODIFIED db activity data");
		debug_filtered_activity_data(%modified_db_data);
	}

	my $modified_row_count = scalar(keys %modified_db_data);
	if ($modified_row_count == 0) {
		debug("There is NO Modified DB data") if $sub_debug;
		return;
	}

	#	Get Dimensions of Sheet Cells
	my($min_row, $max_row) = $worksheet->RowRange();
	my($min_col, $max_col) = $worksheet->ColRange();

	#	Get Specifications
	my %sheet_spec = %{$spec{sheet}{$worksheet->{Name}}};
	unless (%sheet_spec) {
		debug("There's no Sheet Specification for $worksheet->{Name}, so we're skipping it") if $sub_debug;
		return;
	}
	my $project_id = $sheet_spec{project_id};
	debug("project_id=$project_id") if $sub_debug;
	fatal_error("Project ID Not defined for sheet '$worksheet->{Name}'", $spec) unless $project_id;
	my $update_precedence = $sheet_spec{update_precedence} || 'db';
	fatal_error("Update Precedence has bad value of '$update_precedence'") unless $update_precedence =~ /^(db|sheet)$/;
	my $db_update_precedence = $update_precedence eq 'db';
	my %column_spec = %{$sheet_spec{column}};

	#	Find the Index of the record_id
	my $record_id_column_index = -1;
	while (my($column_name, $db_field) = each(%column_spec)) {
		if ($db_field eq 'record_id') {
			$record_id_column_index = map_alpha26_to_0based_col_index($column_name);
			debug("record_id_column_index=$record_id_column_index") if $sub_debug;
			last;
		}
	}
	fatal_error("record_id is NOT in Column Spec.") if $record_id_column_index == -1;

	#	Update the spreadsheet with Updated DB data
	my $rows_updated;
	debug("$modified_row_count rows of Modified DB Data to Update sheet $worksheet->{Name}") if $sub_debug;
	for (my $row_index = $min_row; $row_index <= $max_row; $row_index++) {
        my $key_cell = $worksheet->{Cells}[$row_index][$record_id_column_index];
		my $record_id = $key_cell->{Val};
		if (exists $modified_db_data{$record_id}) {
			my %db_row = %{$modified_db_data{$record_id}};
			debug("Updating worksheet row $row_index with record_id of $record_id --> " . hash_to_string(\%db_row)) if $sub_debug;
			my $column_updated;
			for (my $column_index = $min_col; $column_index <= $max_col; $column_index++) {
				my $db_field = $column_spec{map_0based_col_index_to_alpha26($column_index)} if %column_spec;
				my $field_updated_in_db_and_sheet = $worksheet->{db_data}{$record_id}{_sync_state} eq 'MODIFIED' && $worksheet->{db_data}{$record_id}{data}{$db_field}{_sync_state} eq 'MODIFIED';
#JJT
				if ($db_field && $db_field ne 'record_id' && (!$field_updated_in_db_and_sheet || $db_update_precedence)) {
        			my $cell = $worksheet->{Cells}[$row_index][$column_index];
					my $old_value = $cell->{Val};
					my $new_value = $db_row{$db_field};
					my $display_value = getDisplayValue($new_value, $db_field, $db_row{type}, $project_id, $user_id);
					debug("$display_value = getDisplayValue($new_value, $db_field, $db_row{type}, $project_id, $user_id)") if $sub_debug;
					$cell->{Val} = $display_value;
					$column_updated = 1;
					#	Invalidate any updates to the same field from sheet
					if ($field_updated_in_db_and_sheet && $db_update_precedence) {
						my $new_sheet_value = $worksheet->{db_data}{$record_id}{data}{$db_field}{value};
						warning("ID $record_id $db_field field Update by DB to '$new_sheet_value' overrides Workbook Update of '$display_value", $spec);
						delete $worksheet->{db_data}{$record_id}{data}{$db_field};
					}	# Row modified
				}	# If db_field
			}	# Column
			$rows_updated++ if $column_updated;
			delete $modified_db_data{$record_id};
		} else {
			debug("Not updating row $row_index because record_id of $record_id was Not updated in ProjectTraq") if $sub_debug;
		}	# If db_row
	}	# row

	#	Complain if all the updates weren't applied
	if ($modified_row_count != $rows_updated) {
		$rows_updated = "No" unless ($rows_updated);
		error("Expected to update $modified_row_count sheet rows, but Actually updated $rows_updated rows:", $spec);
		foreach my $record_id (sort { $a <=> $b } keys %modified_db_data) {
			my %db_row = %{$modified_db_data{$record_id}};
			my $debug_row_data = "Database Update Not applied to sheet because ID of $record_id is Not on Sheet: ";
			while (my($field, $value) = each(%db_row)) {
				next if $field eq 'record_id';	# Skip Key
				$debug_row_data .= "$field=$value,";
			}	# Field
			$debug_row_data =~ s/,$//;	# Trim trailing comma
			error($debug_row_data, $spec);
		}
	}
	$rows_updated = 'No' unless ($rows_updated);
	my $prefix = $dry_run ? "If this had not been a Dry Run, then it would have Updated" : "Updated";
	user_log("$prefix $rows_updated rows in sheet $worksheet->{Name} from the database", $spec);
}
#
#	Update DB with Spreadsheet Modifications
#
sub update_db_with_sheet_mods {
	my($worksheet, $spec, %modified_db_data) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	my $row_count = scalar(keys %{$worksheet->{db_data}});
	unless ($row_count) {
		debug("No rows of data on sheet $worksheet->{Name}:") if $sub_debug;
		return;
	}

	my %sheet_spec = %{$spec{sheet}{$worksheet->{Name}}};
	my $project_id = $sheet_spec{project_id};
	debug("project_id=$project_id") if $sub_debug;
	fatal_error("Project ID Not defined for sheet '$worksheet->{Name}'", $spec) unless $project_id;

	my $rows_updated;
	debug("$row_count rows of data on sheet $worksheet->{Name} to Update DB with:") if $sub_debug;
	foreach my $record_id (sort { $a <=> $b } keys %{$worksheet->{db_data}}) {
		my %old_db_row = db_GetRecord($record_id);
		my %updated_db_row = %old_db_row;
		if ($worksheet->{db_data}{$record_id}{_sync_state} eq 'MODIFIED') {
			my %sheet_data_row = %{$worksheet->{db_data}{$record_id}};
			my $some_field_updated;
DB_FIELD:	foreach my $db_field (keys %{$sheet_data_row{data}}) {
				my %sheet_db_field = %{$sheet_data_row{data}{$db_field}};
				if ($sheet_db_field{_sync_state} eq 'MODIFIED') {
					my $new_value = $sheet_db_field{value};
					my $new_internal_value = getMenuValue($project_id, $db_field, $new_value, $old_db_row{type}, $user_id);
					debug("$new_internal_value = getMenuValue($project_id, $db_field, $new_value, $old_db_row{type}, $user_id)") if $sub_debug;
					my $no_internal_value = !defined($new_internal_value);
					if ($no_internal_value) {
						error("Unable to update DB with $db_field on row with ID of $record_id because there's No Menu Value for '$new_value'", $spec);
						next DB_FIELD;
					}
					# Append this field if one already exists
					if (exists $updated_db_row) {
						$updated_db_row{$db_field} .= $new_internal_value;
					} else {
						$updated_db_row{$db_field} = $new_internal_value;
					}
					$some_field_updated = 1;
				} # Modified Field
			} # DB Fields
			if ($some_field_updated && !$dry_run) {
				debug(hash_to_string(\%old_db_row,     'old_db_row')) if $sub_debug;
				debug(hash_to_string(\%updated_db_row, 'updated_db_row')) if $sub_debug;
				my $hashes_are_equal = equal_hashes(\%old_db_row, \%updated_db_row);
				debug("These hashes are" . ($hashes_are_equal ? "" : " NOT") . " equal") if $sub_debug;
				if (!$hashes_are_equal) {
					# JJT db_UpdateRecord(\%updated_db_row, \%old_db_row, $user_id);
					$rows_updated++;
				}
			}
		} #	Modified Row
	}
	$rows_updated = 'No' unless ($rows_updated);
	my $prefix = $dry_run ? 'If this had not been a Dry Run, then it would have Updated' : 'Updated';
	user_log("$prefix $rows_updated rows in the database from sheet $worksheet->{Name}", $spec);
	debug() if $sub_debug;
}
#
#	Debug the Parsed DB Data
#
sub debug_filtered_activity_data {
	my %filtered_activity_data = @_;

	my $row_count = scalar(keys %filtered_activity_data);
	if ($row_count == 0) {
		debug("There is NO Parsed DB data");
		return;
	}

	debug("row_count=$row_count");
	foreach my $record_id (sort {$a <=> $b} keys %filtered_activity_data) {
		my %row = %{$filtered_activity_data{$record_id}};
		debug("record_id=$record_id --> " . hash_to_string(\%row));
	}
}
#
#	Parse the Activity Data into a New/Modified Hash
#
sub filter_activity {
	my ($new_rows, %sql_results) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;
	debug("new_rows=$new_rows") if $sub_debug;
	my %filtered_results;

	my $db_row_count = scalar(@{$sql_results{record_id}});
	debug("db_row_count=$db_row_count:") if $sub_debug;
	my $last_record_id;
	my %row;
	for (my $i = 0; $i < $db_row_count; $i++) {
		my $record_id = $sql_results{record_id}[$i];
		if ($record_id != $last_record_id && defined($last_record_id)) {
			filter_row($new_rows, $last_record_id, \%filtered_results, %row);
			%row = undef;
		}	# New Record ID

		my $field_name= $sql_results{fieldname}[$i];
		my $old_value = $sql_results{oldvalue}[$i];
		my $new_value = $sql_results{newvalue}[$i];

		$row{$field_name} = $new_value;
		$row{_sync_state} = "NEW" if $field_name eq 'record_id' && $old_value eq 'New Record';

		if ($sub_debug) {
			my $debug_row_data = "record_id=$record_id --> ";
			foreach my $db_field (keys %sql_results) {
				my $field_data = $sql_results{$db_field}[$i];
				$debug_row_data .= "$db_field=$field_data," if $field_data;
			}	# Field
			$debug_row_data =~ s/,$//;	# Trim trailing comma
			debug("$debug_row_data") if $sub_debug;
		}	# Debug

		$last_record_id = $record_id;
	}	# Row
	filter_row($new_rows, $last_record_id, \%filtered_results, %row);
	debug() if $sub_debug;

	return %filtered_results;
}
#
#	Filter a row for Newness
#
sub filter_row {
	my($new_rows, $record_id, $filtered_results_ptr, %row) = @_;
	verbose_debug("new_rows=$new_rows, record_id=$record_id, row=" . hash_to_string(\%row));

	return if !defined($new_rows) && $row{_sync_state} eq 'NEW';
	return if  defined($new_rows) && $row{_sync_state} ne 'NEW';

	delete $row{_sync_state};
	verbose_debug("record_id=$record_id got through the filter successfully");
	$$filtered_results_ptr{$record_id} = \%row;
}
#
#	Debug Database Data
#
sub debug_db_data {
	my(%sql_results) = @_;

	my $db_row_count = $sql_results{record_id} ? scalar(@{$sql_results{record_id}}) : 0;

	unless ($db_row_count) {
		debug("No Database Data for this Spreadsheet");
		return;
	}

	debug("$db_row_count rows of DB data:");
	for (my $i = 0; $i < $db_row_count; $i++) {
		my $debug_row_data = "record_id=$sql_results{record_id}[$i] --> ";
		foreach my $db_field (keys %sql_results) {
			next if $db_field eq 'record_id';	# Skip Key
			my $field_data = $sql_results{$db_field}[$i];
			$debug_row_data .= "$db_field=$field_data," if $field_data;
		}	# Field
		$debug_row_data =~ s/,$//;	# Trim trailing comma
		debug("$debug_row_data");
	}	# Row
	debug();
}
#
#	Write out a spreadsheet, within a workbook
#
sub write_sheet {
	my($input_workbook, $input_worksheet, $output_workbook, $sheet_index, $new_row_count, $spec) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;
	my(%input_format_keys);			# Hash of all input cell format keys
	debug("new_row_count=$new_row_count") if $sub_debug;
	#
	my($sheet_name) = $input_worksheet->{Name};
	debug("sheet_name=$sheet_name");
	my($output_sheet) = $output_workbook->add_worksheet($sheet_name);

	#	Get the Range of Row and Column Indexes
	my($min_row, $max_row) = $input_worksheet->RowRange();
	debug("\tmin_row=$min_row, max_row=$max_row") if $sub_debug;
	my($min_col, $max_col) = $input_worksheet->ColRange();
	debug("\tmin_col=$min_col, max_col=$max_col") if $sub_debug;

	#	Duplicate Row Heights
	my($default_row_height) = $input_worksheet->{DefRowHeight};
	if ($input_worksheet->{RowHeight}) {
		my(@row_heights) = @{$input_worksheet->{RowHeight}};
		debug("\tThere are " . scalar(@row_heights) . " row_heights=" . join(',', @row_heights)) if $sub_debug;
		for (my($row_index) = $min_row; $row_index <= $max_row; $row_index++) {
			my($this_row_height) = $row_heights[$row_index] > 0 ? $row_heights[$row_index] : $default_row_height;
			$output_sheet->set_row($row_index, $this_row_height);
		}
	}

	#	Duplicate Column Widths
	if ($input_worksheet->{ColWidth}) {
		my(@col_widths)  = @{$input_worksheet->{ColWidth}};
		debug("\tThere are " . scalar(@col_widths) . " col_widths=", join(',', @col_widths)) if $sub_debug;
		for (my($col_index) = $min_col; $col_index <= $max_col; $col_index++) {
			my($this_col_width) = $col_widths[$col_index];
			$this_col_width = 0 if $this_col_width < 0;
			if ($this_col_width > 0) {
				$output_sheet->set_column($col_index, $col_index, $this_col_width);
			} else {
				$output_sheet->set_column($col_index, $col_index, -$this_col_width, undef, 1);
			}
		}
	}

	#	Handle Print Areas
	my($printAreas)  = $input_workbook->{PrintArea}[$sheet_index];
	if ($printAreas) {
		my(@printAreas)  = @{$printAreas};
		my($printArea) = $printAreas[0];
		my($start_row, $start_col, $end_row, $end_col) = @{$printAreas[0]};
		debug("\tPrint Area: start_row=$start_row, start_col=$start_col, end_row=$end_row, end_col=$end_col") if $sub_debug;
		$output_sheet->print_area($start_row, $start_col, $end_row, $end_col);
	}

	#	Outer Row Loop
	for (my($row_index) = $min_row; $row_index <= $max_row; $row_index++) {
		debug("row_index=$row_index:\n") if $sub_debug;

		#	Inner Cell Loop
		for (my($col_index) = $min_col; $col_index <= $max_col; $col_index++) {
			my($cell) = $input_worksheet->{Cells}[$row_index][$col_index];
			my($type) = $cell->{Type};
			my($code) = $cell->{Code};
			my($val) = $cell->{Val};
			my($formula) = $cell->{Formula};

			#	Cell Formatting
			my($this_cell_format) = $cell->{Format};
			my(%format);
			my($cell_format);
			if ($this_cell_format) {
				%format = %{$this_cell_format};
				$cell_format = handle_formatting(\%format, $type, $code, $output_workbook);
				#	Store all of the format keys to show at the end
				foreach my $key (keys %format) {	# Hash of _all_ formats seen
					$input_format_keys{$key} = 1;
				}
			} else {	#	No Cell Format
			}

			#	Write out the cell
			debug("\tcol_index=$col_index, val=\"$val\"\, type=$type, code=$code, this_cell_format=$this_cell_format") if $sub_debug;
			write_cell($output_sheet, $val, $type, $code, $row_index, $col_index, $cell_format, $formula, $spec);
		}	# End of Column Loop
		debug() if $sub_debug;
	}	# End of Row Loop
	$max_row = 0 if $max_row < 0;
	debug("Wrote $max_row rows to sheet $sheet_name") if $sub_debug;

	#	Duplicate the Conditional Formats
	my @condFmts;
	if (defined($input_worksheet->{CondFmt})) {
		@condFmts = @{$input_worksheet->{CondFmt}};
		debug('There are ' . scalar(@condFmts) . ' Conditional Formats') if $sub_debug;
		$output_sheet->set_conditional_formatting(\@condFmts, $new_row_count);
	} else {
		debug("No CondFmt records in sheet $input_worksheet->{Name}") if $sub_debug;
	}

	#	Verbose listing of input format hashes
	if ($sub_debug) {
		#	List all format keys encountered in the input file
		debug("There are " . scalar(keys %input_format_keys) . " input format keys in this spreadsheet:");
		foreach my $key (sort keys %input_format_keys) {
			debug("\t$key");
		}
	}
}
#
#	Debug the output formats
#
sub debug_output_formats {
	debug("There are ", scalar(keys(%output_format_props)), " output formats:");
	while (my($key, $value) = each(%output_format_props)) {
		my(%format_props) = %$key;
		my($format) = $value;
		debug("\tFormat $format is as follows:");
		while (my($key2, $value2) = each(%format_props)) {
			debug("\t\t$key2 = $value2");
		}
	}
}
#
#	Output an Warning Message
#
sub warning {
	my ($msg, $spec) = @_;
	output_error("WARNING: $msg", $spec);
}
#
#	Output an Error Message
#
sub error {
	my ($msg, $spec) = @_;
	output_error("ERROR: $msg", $spec);
}
#
#	A Catastrophic Error has Occurred
#
sub fatal_error {
	supportingFunctions::doError("FATAL ERROR: $_[0]");
	exit();
}
#
#	Output an error
#
sub output_error {
	my ($msg, $spec) = @_;

	user_log($msg, $spec);
}
#
#	Hash to_string subroutine
#
sub hash_to_string {
	my $hash_ptr = shift;
	my $hash_name = shift;
	my $output = "";

	$output .= "Hash $hash_name:" if $hash_name;
	while (my($key, $value) = each(%$hash_ptr)) {
		$output .= " $key=$value";
	}

	return $output;
}
#
#	Write out the contents of the cell based on the type of its value
#
sub write_cell {
	my($output_sheet, $value, $type, $code, $row_index, $col_index, $format, $formula, $spec) = @_;

	if ($formula) {
		verbose_debug("value=$value, type=$type, code=$code, row_index=$row_index, col_index=$col_index, format=$format, formula=\"$formula\"");

		if ($formula eq "#NAME") {
			error("Formula is #NAME, so we're skipping it", $spec);
			return;
		} elsif ($formula =~ /^IF/) {
			error("Will not write formula '$formula' at Cell [$row_index,$col_index] because it would corrupt the target spreadsheet - writing cell value only", $spec);
			if ($value =~ /-?\d+/) {
				$output_sheet->write_number($row_index, $col_index, $value, $format);
			} else {
				$output_sheet->write_string($row_index, $col_index, $value, $format);
			}
			return;
		} else {
			$output_sheet->write_formula($row_index, $col_index, "=$formula", $format, $value);
		}
		verbose_debug("Returning from write_cell()");
		return;
	}

	if (!$value) {
		$output_sheet->write_blank($row_index, $col_index, $format);
	} elsif ($code) {
		$output_sheet->write_unicode($row_index, $col_index, $value, $format);
	} elsif ($type eq 'Text') {
		$output_sheet->write_string($row_index, $col_index, $value, $format);
	} elsif ($type eq 'Numeric') {
		$output_sheet->write_number($row_index, $col_index, $value, $format);
	} elsif ($type eq 'Date') {
		my($date_string) = Spreadsheet::ParseExcel::Utility::ExcelFmt("yyyy-mm-dd", $value, $flag_1904) . "T";
		$output_sheet->write_date_time($row_index, $col_index, $date_string, $format);
	} else {
		fatal_error("Unidentified type of $type at [$row_index, $col_index]");
	}
}
#
#	Handle cell formatting
#
sub handle_formatting {
	my($format_hash_ptr, $type, $code, $output_workbook) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;
	my(%format) = %{$format_hash_ptr};

	my(%input_font) = %{$format{Font}};
	my($pattern, $front_color, $back_color) = @{$format{Fill}};
	my($border_kind, $border_style, $border_color) = @{$format{BdrDiag}};
	my($left_border_style, $right_border_style, $top_border_style, $bottom_border_style) = @{$format{BdrStyle}};
	my($left_border_color, $right_border_color, $top_border_color, $bottom_border_color) = @{$format{BdrColor}};

	#	Try to handle unicode font name
	my($code_font);
	if ($WORK_ON_UNICODE_FONT_NAME) {
		if ($code) {
			my($font_name) = $input_font{Name};
			debug("font_name=$font_name, utf8::is_utf8=", utf8::is_utf8($font_name)) if $sub_debug;
			my(@font_chars) = split(//, $font_name);
			debug("font_chars=\"", join(':', @font_chars)) if $sub_debug;
			for (my($i) = 0; $i <= $#font_chars; $i++) {
				my($font_char) = $font_chars[$i];
				debug("font_chars[", $i, "]=\"", $font_char, "\", ord($font_char)=", ord($font_char)) if $sub_debug;
			}
			#	Try packing/unpacking
			my($font_chars) = pack('C0U*', @font_chars);
			debug("font_chars=\"", $font_chars) if $sub_debug;
			my($font_x) = unpack('U*', $font_name);
			debug("font_x=\"", $font_x, "\", utf8::is_utf8=", utf8::is_utf8($font_x)) if $sub_debug;
			#	Try decoding/downgrading
			my($font_y) = decode("utf8", $font_name);
			debug("font_y=\"", $font_y, "\", utf8::is_utf8=", utf8::is_utf8($font_y)) if $sub_debug;
			my($downgrade_result) = utf8::downgrade($font_name);
			debug("After downgrade, font_name=\"", $font_name, "\", downgrade_result=", $downgrade_result, ", is_utf8=", utf8::is_utf8($font_name)) if $sub_debug;
			#	Try the Unicode::String package
			Unicode::String->stringify_as($code);
			my($font_unicode_string) = Unicode::String->new($font_name);
			debug("Using Unicode::String($code), we get ", $font_unicode_string->as_string()) if $sub_debug;
			#	Now use one of them to see if it works
			$code_font = $font_y;
		}
	}

	my(%new_format_props) = (
		font			=> $input_font{Name},
		size			=> $input_font{Height},
		color			=> $input_font{Color},
		bold			=> $input_font{Bold},
		italic			=> $input_font{Italic},
		underline		=> $input_font{Underline},
		font_strikeout	=> $input_font{Strikeout},
		font_script		=> $input_font{Super},
		locked			=> $format{Lock},
		hidden			=> $format{Hidden},
		align			=> $HORIZONTAL_ALIGNMENT_MAP[$format{AlignH}],
		valign			=> $VERTICAL_ALIGNMENT_MAP[$format{AlignV}],
		rotation		=> $format{Rotate},
		text_wrap		=> $format{Wrap},
		text_justlast	=> $format{JustLast},
		indent			=> $format{Indent},
		shrink			=> $format{Shrink},
		pattern			=> $pattern,
		bg_color		=> $back_color,
		fg_color		=> $front_color,
		border			=> $border_kind,
		bottom			=> $bottom_border_style,
		top				=> $top_border_style,
		left			=> $left_border_style,
		right			=> $right_border_style,
		border_color	=> $border_color,
		bottom_color	=> $bottom_border_color,
		top_color		=> $top_border_color,
		left_color		=> $left_border_color,
		right_color		=> $right_border_color
	);
	if ($WORK_ON_UNICODE_FONT_NAME) {
		if ($code) {
			$new_format_props{font}=$code_font;
		}
	}
	if ($type eq 'Date') {
		$new_format_props{num_format} = $DATE_FORMAT_STRING;
	}
	#
	#	Debugging
	#
	verbose_debug("new_format_props=", hash_to_string(\%new_format_props));
	#
	#	See if we've already used this format in a previous cell
	#
	my($this_format);
	my($existing_format);
	my($match);
	my($new_format_props_count) = scalar(keys(%new_format_props));
	while (my($key, $value) = each(%output_format_props)) {
		my(%old_format_props) = %$key;
		next if $new_format_props_count != scalar(keys(%old_format_props));
		my($old_format) = $value;
		$match = 1;
		verbose_debug("-- Comparing to another existing format:");
		while (my($key2, $value2) = each(%old_format_props)) {
			verbose_debug("key2=$key2, Comparing new value of $new_format_props{$key2} to existing value of $old_format_props{$key2}");
			if ($new_format_props{$key2} ne $old_format_props{$key2}) {
				$match = 0;
				last;
			}
		}
		if ($match) {
			$existing_format = $old_format;
			last;
		}
	}
	#
	#	If we have a match, then move on, otherwise create a new format for it
	#
	if ($match) {
		$this_format = $existing_format;
		verbose_debug("\tWe already have this format");
	} else {
		$this_format = $output_workbook->add_format(%new_format_props);
		$output_format_props{\%new_format_props} = $this_format;
		verbose_debug("\tThis is a new format");
	}
	#
	#	Return the format for this cell
	#
	return ($this_format);
}
#
#	Get the data from the database
#
sub read_db_data {
	my($sheet_name, $last_date) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	debug("sheet_name=$sheet_name, last_date=$last_date") if $sub_debug;
	#
	unless(defined $spec{sheet}{$sheet_name}) {
		debug("The spec. does NOT refer to sheet $sheet_name, so we copy it 'as is'") if $sub_debug;
		return undef;
	}

	#	Loop through the Workbook's spreadsheets
	my %sql_results;
	my %sheet_spec = %{$spec{sheet}{$sheet_name}};
	if (exists $sheet_spec{column}) {
		debug("\tColumns are as follows:") if $sub_debug;
		while (my($key, $value) = each %{$sheet_spec{column}}) {
			debug("\t\t$key=$value") if $sub_debug;
		}
	}
	%sql_results = get_db_data($last_date);
	if (exists $sql_results{record_id}) {
		my $row_count = scalar(@{$sql_results{record_id}});
		debug("row_count=$row_count") if $sub_debug;
	} else {
		debug("Query did NOT return any rows.") if $sub_debug;
	}

	return (%sql_results);
}
#
#	Get the data from the database
#
sub get_db_data {
	my($last_date) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	debug("last_date=$last_date") if $sub_debug;

	#	Build and Execute the SQL Query
	my $sql = "SELECT traq_activity.*, traq_records.type FROM traq_activity, traq_records WHERE traq_activity.record_id=traq_records.record_id AND tablename='traq_records' AND date > '$last_date' ORDER BY date";
	debug("sql=$sql") if $sub_debug;
    my %sql_results = doSql($sql);
	unless(%sql_results) {
		debug("No rows were returned by the query") if $sub_debug;
		return undef;
	}

	my $row_count = scalar(@{$sql_results{record_id}});
	debug("Query returned $row_count rows") if $sub_debug;

	if ($sub_debug) {
		for (my $i = 0; $i < $row_count; $i++) {
			my $field_data;
			foreach my $field_name (keys %sql_results) {
				$field_data .= "$field_name=$sql_results{$field_name}[$i],";
			}
			$field_data =~ s/,$//;
			debug("Row $i: $field_data");
		}
	}

	return (%sql_results);
}
#
#	Diff the Input WorkBooks
#	
sub diff_workbooks {
	my($previous_workbook, $current_workbook, $spec) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	#	If there's no Previous workbook, then bail
	fatal_error("There's no Previous Workbook in the Database") unless ($previous_workbook);

	#	Loop thru sheets of both workbooks (current input and previous output)
	my $sheet_index = 0;
	foreach my $current_worksheet (@{$current_workbook->{Worksheet}}) {
		#	Find the Worksheet in the Previous Workbook by the same Name
		my $found_index;
		my $current_worksheet_name = $current_worksheet->{Name};
		user_log("Reading sheet $current_worksheet_name...", $spec);
		for (my $search_index = 0; $search_index < scalar(@{$previous_workbook->{Worksheet}}); $search_index++) {
			my $previous_worksheet_name = $previous_workbook->{Worksheet}[$search_index]{Name};
			debug("Comparing Current Worksheet Name '$current_worksheet_name' to Previous Worksheet Name '$previous_worksheet_name'") if $sub_debug;
			if ($previous_worksheet_name eq $current_worksheet_name) {
				$found_index = $search_index;
				debug("Found the Previous Worksheet at Index $found_index") if $sub_debug;
				last;
			}
		}
		unless (defined $found_index) {
			warning("There's no sheet named $current_worksheet_name in the Previous Workbook", $spec);
		}
		debug("Found sheet with name $current_worksheet->{Name} in the Previous Workbook at Index of $found_index") if $sub_debug;
		my $previous_worksheet = $previous_workbook->{Worksheet}[$found_index];
		debug("worksheet=$previous_worksheet->{Name}") if $sub_debug;

		diff_worksheet($current_worksheet, $previous_worksheet, $spec);
		$sheet_index++;
	}	# Worksheet
}
#
#	Diff worksheets
#
sub diff_worksheet {
	my($current_worksheet, $previous_worksheet, $spec) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	#	Loop through the DB rows drawn from the spreadsheet(s)
ROW:foreach my $record_id (sort {$a <=> $b} (keys(%{$current_worksheet->{db_data}}))) {
		debug("record_id=$record_id") if $sub_debug;
		my %current_sheet_db_row = %{$current_worksheet->{db_data}{$record_id}};
		my %previous_sheet_db_row;
		%previous_sheet_db_row = %{$previous_worksheet->{db_data}{$record_id}} if exists $previous_worksheet->{db_data}{$record_id};

		unless (%previous_sheet_db_row) {
			error("There's a new row on the spreadsheet with ID $record_id - New rows should only come from ProjectTraq", $spec);
			$current_worksheet->{db_data}{$record_id}{_sync_state} = "NEW";
			next ROW;
		}

		#	Loop through the database fields
		my $modified = 0;
FIELD:	foreach my $db_field (keys %{$current_sheet_db_row{data}}) {
			verbose_debug("db_field=$db_field");
			if ($db_field =~ /^_/) {		# Skip Non-Data fields
				verbose_debug("$db_field is a Non-Data Field, so we're skipping the comparison");
				$current_worksheet->{db_data}{$record_id}{data}{$db_field}{_sync_state} = "IGNORE";
				next FIELD;
			}
			if ($db_field eq 'record_id') {# Skip key field
				verbose_debug("$db_field is the Unique Key, so we're skipping the comparison");
				$current_worksheet->{db_data}{$record_id}{data}{$db_field}{_sync_state} = "IGNORE";
				next FIELD;
			}
			unless (exists $previous_sheet_db_row{data}{$db_field}) {
				error("record_id=$record_id There's no Previous Value for $db_field, so we're skipping the comparison", $spec);
				$current_worksheet->{db_data}{$record_id}{data}{$db_field}{_sync_state} = "NEW";
				$modified = 1;
				next FIELD;
			}
			my $previous_value = $previous_sheet_db_row{data}{$db_field}{value};
			my $current_value = $current_sheet_db_row{data}{$db_field}{value};
			verbose_debug("Comparing Current value of '$current_value' to Previous value of '$previous_value'");
			if ($current_value eq $previous_value) {
				verbose_debug("record_id=$record_id: UN-MODIFIED: $db_field='$current_value'");
				$current_worksheet->{db_data}{$record_id}{data}{$db_field}{_sync_state} = "UN-MODIFIED";
				next FIELD;
			} else {
				verbose_debug("record_id=$record_id: MODIFIED: $db_field='$previous_value'-->'$current_value'");
				$current_worksheet->{db_data}{$record_id}{data}{$db_field}{_sync_state} = "MODIFIED";
				$modified = 1;
				next FIELD;
			}	# If Value Changed
		}	# DB Field Loop
		$current_worksheet->{db_data}{$record_id}{_sync_state} = $modified ? 'MODIFIED' : 'UN-MODIFIED';
		verbose_debug("record_id=$record_id: _sync_state=$current_worksheet->{db_data}{$record_id}{_sync_state}");
	}	# Unique Key
}
#
#	Print our db_data data from a workbook/sheet hash
#
sub debug_sheet_db_data {
	my($worksheet) = @_;

	my $row_count = scalar(keys %{$worksheet->{db_data}});
	unless ($row_count) {
		debug("No rows of data on sheet $worksheet->{Name}:");
		return;
	}
	debug("$row_count rows of data on sheet $worksheet->{Name}:");
	foreach my $record_id (sort { $a <=> $b } keys %{$worksheet->{db_data}}) {
		my $data;
		$data = "($worksheet->{db_data}{$record_id}{_sync_state})-->";
		my %sheet_data_row = %{$worksheet->{db_data}{$record_id}};
		foreach my $db_field (keys %{$sheet_data_row{data}}) {
			my %db_field = %{$sheet_data_row{data}{$db_field}};
			$data .= "$db_field=$db_field{value}";
			$data .= "($db_field{_sync_state})";
			$data .= ",";
		}
		$data =~ s/\,$//;	# Trim trailing delimiter
		debug("record_id=$record_id, sheet_data=$data");
	}
	debug();
}
#
#	Debug
#
sub debug {
	output_debug_message(@_, 2);
}
#
#	Verbose Debug
#
sub verbose_debug {
	output_debug_message(@_, 2) if $VERBOSE_DEBUG;
}
#
#	Print out a Debug Message
#
sub output_debug_message {
	my $message = shift;
	my $num_levels = shift || 1;

	my($package, $filename, $line, $subroutine, $has_args, $wantarray) = caller($num_levels);
	my($my_package, @dummies) = caller(0);
	$subroutine =~ s/^${my_package}:://;
	my $debug_message = "DEBUG: $subroutine: $message";
	supportingFunctions::log($debug_message, 5);
}
#
#	Upload a Workbook file and store in the DB
#
sub upload_workbook_into_db {
	my $input_file_name	= $cgi->param('input_file');
	fatal_error("Input File is Undefined") unless ($input_file_name);
	my $input_date = $cgi->param('input_date');
	warning("Input Date is Undefined, so we'll use 'NOW'") unless ($input_date);
	debug("input_file_name=$input_file_name");
	my $book_data_ptr = upload_file($input_file_name);
	store_workbook_in_db($input_file_name, $book_data_ptr, $input_date);
	user_log("Imported Spreadsheet");
}
#
#	Store a workbook in the Db
#
sub store_workbook_in_db {
	my($input_file_name, $book_data_ptr, $input_date) = @_;
	my $spec_name = $cgi->param('spec_file');
	fatal_error("Spec File is Undefined") unless ($spec_name);
	debug("spec_name=$spec_name, input_file_name=$input_file_name, input_date=$input_date") if $DEBUG;

	#	Store the Workbook contents in the DB
	my $db_connection = dbConnect();
	my $sql = 'INSERT INTO traq_workbooks (spec_name, file_name, workbook, creation_ts) VALUES (?, ?, ?, ';
	$sql .= $input_date ? "'$input_date'" : 'NOW()';
	$sql .= ')';
	debug("sql=$sql") if $DEBUG;
	use bytes;
	my $db_statement = $db_connection->prepare($sql);
	$db_statement->execute($spec_name, $input_file_name, $$book_data_ptr);
	no bytes;
	$db_statement->finish;
	$db_connection->disconnect;
}
#
#	Read a workbook file from the DB
#
sub get_latest_workbook_from_db {
	my $spec_name = $cgi->param('spec_file');
	debug("spec_name=$spec_name") if $DEBUG;
	fatal_error("No spec. file specified") unless ($spec_name);
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	#	Get the Workbook from the DB
	use bytes;
	my $sql = qq/SELECT file_name, workbook, creation_ts FROM traq_workbooks WHERE spec_name = "$spec_name" AND creation_ts = (SELECT MAX(creation_ts) FROM traq_workbooks WHERE spec_name = "$spec_name")/;
	debug("sql=$sql") if $DEBUG;
    my (%sql_results) = doSql($sql);
	return undef unless (%sql_results);
	my $file_name	= $sql_results{file_name}	[0];
	my $data		= $sql_results{workbook}	[0];
	my $creation_ts	= $sql_results{creation_ts}	[0];
	debug("spec_name=$spec_name, file_name=$file_name, creation_ts=$creation_ts, length(data)=" . length($data)) if $DEBUG;

	return (\$data, $creation_ts, $spec_name);
}
#
#	Download latest workbook to the user
#
sub download_latest_workbook {
	#	Get the Workbook from the DB
	my($latest_book_data_ptr, $last_date, $spec) = get_latest_workbook_from_db();
	#	Download the file
	my $download_file_name = download_file($latest_book_data_ptr);
	debug("last_date=$last_date, download_file_name=$download_file_name");
	user_log("Exported Latest Spreadsheet", $spec);
}
#
#	User Log Delimiter
#
sub user_log_delimiter {
	user_log($USER_LOG_DELIMITER);
}
#
#	User Log
#
sub user_log {
	my $msg = shift;
	my $spec_name = shift || "";
	chomp($msg);
	my $db_handle = dbConnect();
	$msg = $db_handle->quote($msg);
	my $sql = "INSERT INTO traq_workbook_logs (insert_ts, spec_name, entry) VALUES (NOW(), '$spec_name', $msg)";
	debug("sql=$sql") if $DEBUG;
	$db_handle->do($sql);
	$db_handle->disconnect();
}
#
#	Get the contents of a binary file
#
sub get_file_contents {
	my($file_name) = @_;
	my $sub_debug = 0 || $VERBOSE_DEBUG;

	my @stat_fields = stat($file_name);
	my $file_size = $stat_fields[7];
	open(BINARY_FILE, "<$file_name") || fatal_error("Unable to open File: $file_name");
	my $data;
	my $bytes_read = read(BINARY_FILE, $data, $file_size);
	close(BINARY_FILE);
	fatal_error("Expected $file_size bytes in $file_name, but found $bytes_read") if $bytes_read != $file_size;
	debug("file_size=$file_size, bytes_read=$bytes_read, file_name=$file_name")
if ($sub_debug);
	return \$data;
}
#
#	Get Current DateTimeStamp from the DB
#
sub get_now_from_db {
	my $sql = 'SELECT NOW()';
	debug("sql=$sql") if $DEBUG;
    my (%sql_results) = doSql($sql);
	fatal_error("Unable to get the current timestamp from the database") unless (%sql_results);
	my $now	= $sql_results{'NOW()'}[0];

	return $now;
}
#
#	Compare hashes that are only one level deep
#
sub equal_hashes {
	my ($hash1, $hash2) = @_;

	return 0 if scalar(keys %$hash1) != scalar(keys %$hash2);

	while (my ($key, $value) = each (%$hash1)) {
		return 0 if $$hash2{$key} ne $value;
	}

	return 1;
}
