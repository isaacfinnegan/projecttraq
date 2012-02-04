#
#	Description: Worksheet specification for sync.cgi
#
#	Detail: The following hash values are defined at the worksheet level:
#		...{project_id}        = <project#_for_this_sheet>
#		...{update_precedence} = {db|sheet}         // Optional, defaults to db
#		...{first_data_row}    = <first_row_with_data>
#		$spec{sheet}{<sheet-name>}{column} = {
#			<worksheet-column-name>	=> <db-field-name>,
#			...
#		};
#
#	Additional Detail:
#		The update_precedence spec. above is only relevant
#		when both the DB and the spreadsheet have updates
#		to the same row/column.
#		If it's set to 'db',    then the DB update wins.
#		If it's set to 'sheet', then the Spreadsheet update wins.
#		If the update_precedence isn't specified, then it defaults to 'db'.
#
$spec{sheet}{Sheet1}{project_id} = 87;
$spec{sheet}{Sheet1}{update_precedence} = 'db';
$spec{sheet}{Sheet1}{first_data_row} = 4;
$spec{sheet}{Sheet1}{column} = {
	A	=> 'status',
	B	=> 'record_id',
};
