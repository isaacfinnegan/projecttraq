# No database is created in this file, the database
# and user permissions for the database info need 
# to be setup separately.

################
# table creation
################


# acl_traq_components
CREATE TABLE acl_traq_components(
	groupid INT(9) NOT NULL,
	componentid INT(9) NOT NULL,
	INDEX groupid (groupid, componentid)
);

# acl_traq_projects
CREATE TABLE acl_traq_projects(
	groupid INT(9) NOT NULL,
	projectid INT(9) NOT NULL,
	INDEX groupid (groupid, projectid)
);

# acl_traq_records
CREATE TABLE acl_traq_records(
	groupid INT(9) NOT NULL,
	record_id INT(9) NOT NULL,
	INDEX acl_rec_grp (record_id, groupid),
	INDEX acl_grp_rec (groupid, record_id)
);


# groups
CREATE TABLE groups(
	groupid INT(9) NOT NULL AUTO_INCREMENT,
	groupname VARCHAR(32) NOT NULL,
	description MEDIUMTEXT NOT NULL,
	PRIMARY KEY (groupid),
	UNIQUE groupid_2 (groupid),
	INDEX groupid (groupid)
);


# `logins`
CREATE TABLE `logins`(
	username varchar(50) NULL,
	userid int(11) NOT NULL AUTO_INCREMENT,
	password varchar(50) NULL,
	email varchar(50) NULL,
	first_name varchar(20) NOT NULL,
	last_name varchar(30) NOT NULL,
	bugtraqprefs text NULL,
	active varchar(10) NOT NULL,
	returnfields tinytext NOT NULL,
	recordeditprivs tinytext NOT NULL,
	tasktraqprefs varchar(255) NOT NULL,
	taskreturnfields tinytext NOT NULL,
	bugreturnfields tinytext NOT NULL,
	passwordChangeDate datetime NULL,
	order1 varchar(20) NULL,
	order2 varchar(20) NULL,
	order3 varchar(20) NULL,
	PRIMARY KEY (userid),
	UNIQUE username (username),
	INDEX username2 (username)
);


# traq_activity
CREATE TABLE traq_activity(
	record_id INT(9) NOT NULL,
	who INT(9) NOT NULL,
	fieldname VARCHAR(32) NULL,
	oldvalue VARCHAR(100) NULL,
	newvalue VARCHAR(100) NULL,
	tablename VARCHAR(32) NOT NULL,
	date DATETIME NULL,
	INDEX record_id (record_id)
);

# traq_attachments
CREATE TABLE traq_attachments(
	attach_id INT(9) NOT NULL AUTO_INCREMENT,
	record_id INT(9) NOT NULL,
	creation_ts DATETIME NOT NULL,
	description TINYTEXT NULL,
	mimetype VARCHAR(50) NULL,
	ispatch INT(4) NULL,
	filename TINYTEXT NOT NULL,
	thedata LONGBLOB NOT NULL,
	submitter_id INT(9) NOT NULL,
	status VARCHAR(16) NULL,
	PRIMARY KEY (attach_id),
	UNIQUE attach_id_2 (attach_id),
	INDEX attach_id (attach_id, record_id)
);

# traq_cc
CREATE TABLE traq_cc(
	record_id INT(9) NOT NULL,
	who INT(9) NOT NULL,
	INDEX record_id (record_id)
);

# traq_components
CREATE TABLE traq_components(
	componentid int(9) NOT NULL AUTO_INCREMENT,
	component varchar(32) NOT NULL,
	projectid int(9) NOT NULL,
	initialowner int(9) NOT NULL,
	initialqacontact int(9) NOT NULL,
	description mediumtext NOT NULL,
	active varchar(20) NULL,
	rec_type varchar(40) NULL,
	component_parent int(11) NULL,
	cc VARCHAR(250) NULL,
	PRIMARY KEY (componentid),
	UNIQUE componentid_2 (componentid),
	INDEX componentid (componentid, projectid)
);
# traq_dependencies
CREATE TABLE traq_dependencies(
	blocked INT(9) NOT NULL,
	dependson INT(9) NOT NULL,
	INDEX blocked (blocked, dependson)
);

# traq_keywordref
CREATE TABLE traq_keywordref(
	record_id INT(9) NOT NULL,
	keywordid INT(9) NOT NULL,
	INDEX record_id (record_id, keywordid)
);

# traq_keywords
CREATE TABLE traq_keywords(
	keywordid INT(9) NOT NULL AUTO_INCREMENT,
	name VARCHAR(24) NOT NULL,
	description MEDIUMTEXT NOT NULL,
	PRIMARY KEY (keywordid),
	UNIQUE keywordid_2 (keywordid),
	INDEX keywordid (keywordid)
);

# traq_longdescs
CREATE TABLE traq_longdescs(
	record_id INT(9) NOT NULL,
	who INT(9) NOT NULL,
	thetext MEDIUMTEXT NOT NULL,
	date DATETIME NULL,
	INDEX record_id (record_id)
);

# traq_menus
CREATE TABLE traq_menus(
	menuname VARCHAR(32) NOT NULL,
	display_value VARCHAR(64) NULL,
	value VARCHAR(64) NOT NULL,
	project VARCHAR(32) NOT NULL,
	rec_type VARCHAR(40) NULL,
	id INT(11) NOT NULL AUTO_INCREMENT,
	def INT(11) NULL,
	PRIMARY KEY (id),
	INDEX menuname (menuname, value, project)
);

# `traq_milestones`
CREATE TABLE `traq_milestones`(
	milestoneid int(9) NOT NULL,
	milestone varchar(64) NOT NULL,
	projectid int(9) NOT NULL,
	sortkey int(9) NOT NULL,
	description mediumtext NOT NULL,
	mile_url text NULL,
	mile_date date NULL,
	INDEX milestoneid (milestoneid),
	INDEX milestonename (milestone),
	INDEX projectid (projectid)
);


# traq_namedqueries
CREATE TABLE traq_namedqueries(
	userid INT(9) UNSIGNED NOT NULL,
	name VARCHAR(64) NOT NULL,
	watchfordiffs INT(4) UNSIGNED NOT NULL,
	linkinfooter INT(4) NOT NULL,
	query MEDIUMTEXT NOT NULL,
	tasks TINYINT(4) NOT NULL,
	bugs TINYINT(4) NOT NULL,
	type VARCHAR(20) NOT NULL,
	url TEXT NULL,
	INDEX userid (userid),
	INDEX userid_name (userid, name)
);

# traq_project
CREATE TABLE traq_project(
	projectid INT(9) NOT NULL AUTO_INCREMENT,
	project VARCHAR(32) NOT NULL,
	description MEDIUMTEXT NOT NULL,
	owner INT(9) NOT NULL,
	archive INT(4) NULL,
	default_dev INT(9) NULL,
	default_qa INT(9) NULL,
	type VARCHAR(20) NOT NULL,
	rec_types VARCHAR(40) NULL,
	cc VARCHAR(250) NULL,
	url VARCHAR(255) NULL,
	newtaskurl VARCHAR(255) NULL,
	newbugurl VARCHAR(255) NULL,
	PRIMARY KEY (projectid),
	UNIQUE projectid_2 (projectid),
	INDEX projectid (projectid, owner)
);

# traq_queries
CREATE TABLE traq_queries(
	userid INT(9) NULL,
	query MEDIUMTEXT NULL,
	queryid INT(12) NULL,
	type VARCHAR(10) NULL,
	sortorder VARCHAR(50) NULL,
	expire DATETIME NULL,
	url_string text null,
	PRIMARY KEY (queryid)
);

# traq_records
CREATE TABLE traq_records(
	record_id int(9) unsigned NOT NULL AUTO_INCREMENT,
	type varchar(32) NOT NULL,
	units_req int(9) unsigned NULL,
	assigned_to int(9) unsigned NULL,
	target_date date NULL,
	severity varchar(16) NULL,
	status varchar(16) NOT NULL,
	creation_ts datetime NOT NULL,
	delta_ts datetime NULL,
	short_desc tinytext NOT NULL,
	bug_op_sys varchar(32) NULL,
	priority varchar(16) NULL,
	projectid int(9) NULL,
	bug_platform varchar(32) NULL,
	reporter int(9) NULL,
	version varchar(16) NULL,
	componentid int(9) NULL,
	resolution varchar(16) NULL,
	target_milestone int(9) NULL,
	qa_contact int(9) NULL,
	tech_contact int(9) NULL,
	status_whiteboard tinytext NULL,
	keywords tinytext NULL,
	lastdiffed datetime NULL,
	reproducibility varchar(16) NULL,
	changelist varchar(32) NULL,
	start_date date NULL,
	ext_ref varchar(32) NULL,
	releasenote varchar(255) NULL,
	PRIMARY KEY (record_id),
	UNIQUE record_id_2 (record_id),
	INDEX record_id (record_id, type)
);

# traq_results
CREATE TABLE traq_results(
	userid INT(9) NULL,
	result TEXT NULL
);

# traq_templates
CREATE TABLE traq_templates(
	category varchar(9) NULL,
	name VARCHAR(64) NOT NULL,
	template MEDIUMTEXT NOT NULL,
	projectid INT(9) NOT NULL,
	type VARCHAR(10) NOT NULL,
	INDEX category (category)
);

# user_groups
CREATE TABLE user_groups(
	groupid INT(9) NOT NULL,
	userid INT(9) NOT NULL,
	INDEX userid (userid),
	INDEX groupid (groupid)
);

CREATE TABLE traq_workbooks (
	spec_name	VARCHAR(255)	NOT NULL,
	file_name	VARCHAR(255)	NOT NULL,
	workbook	LONGBLOB		NOT NULL,
	creation_ts	DATETIME		NOT NULL,
	INDEX spec_name_index (spec_name, creation_ts)
);

CREATE TABLE traq_workbook_logs (
	serial		INT(9)			NOT NULL AUTO_INCREMENT,
	insert_ts	DATETIME		NOT NULL,
	spec_name	VARCHAR(255)	NOT NULL,
	entry		VARCHAR(255)	NOT NULL,
	INDEX serial_index (serial)
);



#######################
# default data creation
#######################

insert into groups (groupname, description) values (
	"System-Admin", "System Administrators");

insert into groups (groupname, description) values (
	"System-Admin-owners", "Owners of System Admin");

insert into groups (groupname, description) values (
	"Users", "Users");
insert into groups (groupname, description) values (
	"Users-owners", "Owners of Users");

insert into logins (userid, first_name, last_name,username,  email,
                active, password)  values (
                1, "System", "Administrator", "admin", "", "Yes", "TEJXGhZZRVXsk");
insert into logins (userid, first_name, last_name,username,  email,
                active, password)  values (
                0, "System", "Visitor", "visitor", "", "Yes", "");

insert into user_groups (groupid, userid) values ("1","1");
insert into user_groups (groupid, userid) values ("2","1");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "New", "1", "bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "Assigned", "2", "bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "Reopened", "5", "bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "Resolved", "9", "bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "Verified", "10", "bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "Closed", "12", "bug");

insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "New", "1", "task");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "Assigned", "2", "task");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "Evaluating", "3", "task");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "In Progress", "4", "task");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "Waiting for Info", "5", "task");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "Reopened", "6", "task");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("status", "Completed", "12", "task");

insert into traq_menus (menuname, display_value, value, rec_type) values
	("severity", "Blocker", "1", "task");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("severity", "High", "2", "task");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("severity", "Medium", "3", "task");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("severity", "Low", "4", "task");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("severity", "Enhancement", "5", "task");

insert into traq_menus (menuname, display_value, value, rec_type) values
	("severity", "Blocker", "1", "bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("severity", "Critical", "2", "bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("severity", "Major", "3", "bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("severity", "Minor", "4", "bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("severity", "Cosmetic", "5", "bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("severity", "Enhancement", "6", "bug");


insert into traq_menus (menuname, display_value, value, rec_type) values
	("priority", "1", "1", "task bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("priority", "2", "2", "task bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("priority", "3", "3", "task bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("priority", "4", "4", "task bug");
insert into traq_menus (menuname, display_value, value, rec_type) values
	("priority", "5", "5", "task bug");

insert into traq_menus (menuname, display_value, value, rec_type, project) values
	("reproducibility", "Always", "Always", "task bug", "0");
insert into traq_menus (menuname, display_value, value, rec_type, project) values
	("reproducibility", "Once", "Once", "task bug", "0");
insert into traq_menus (menuname, display_value, value, rec_type, project) values
	("reproducibility", "Never", "Never", "task bug", "0");

# Bug resolution values
insert into traq_menus (menuname, display_value, value,project, rec_type) values 
	('resolution','Deferred','4','0','bug');
insert into traq_menus (menuname, display_value, value,project, rec_type) values 
	('resolution','Duplicate','5','0','bug');
insert into traq_menus (menuname, display_value, value,project, rec_type) values 
	('resolution','Will not fix','3','0','bug');
insert into traq_menus (menuname, display_value, value,project, rec_type) values 
	('resolution','Works as designed','2','0','bug');
insert into traq_menus (menuname, display_value, value,project, rec_type) values 
	('resolution','Fixed','1','0','bug');
insert into traq_menus (menuname, display_value, value,project, rec_type) values 
	('resolution','Unable to reproduce','6','0','bug');
insert into traq_menus (menuname, display_value, value,project, rec_type) values 
	('resolution','Moved','7','0','bug');

# Task resolution values
insert into traq_menus (menuname, display_value, value,project, rec_type) values 
	('resolution','75%','75','0','task');
insert into traq_menus (menuname, display_value, value,project, rec_type) values 
	('resolution','50%','50','0','task');
insert into traq_menus (menuname, display_value, value,project, rec_type) values 
	('resolution','25%','25','0','task');
insert into traq_menus (menuname, display_value, value,project, rec_type) values 
	('resolution','100%','100','0','task');



update traq_menus set project=0;
