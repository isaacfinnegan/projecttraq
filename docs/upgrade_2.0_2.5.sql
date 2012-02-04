# Change menuname in traq_menus to be same as fieldnames in traq_records

update traq_menus set menuname='bug_platform' where menuname='platforms';
update traq_menus set menuname='bug_op_sys' where menuname='os';
update traq_menus set menuname='version' where menuname='buildid';
update traq_menus set menuname='reproducibility' where menuname='reproduce';


alter table traq_queries
	ADD url_string text null;
	
alter table traq_project
	ADD cc varchar(250) null;

alter table traq_components
	ADD cc varchar(250) null;