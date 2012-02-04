# tested against bugzilla 2.22


# Bug status
delete from ptdb.traq_menus where menuname='status' and rec_type='bug';

insert into  ptdb.traq_menus (menuname,display_value,value,project,rec_type) select 'status',value,id,'0','bug' from bugzilladb.bug_status;


# Bug severity
delete from ptdb.traq_menus where menuname='severity' and rec_type='bug';
insert into ptdb.traq_menus (menuname,display_value,value,project,rec_type) select 'severity',value,id,'0','bug' from bugzilladb.bug_severity;

# Bug op_sys 
insert into ptdb.traq_menus (menuname,display_value,value,project,rec_type) select 'bug_op_sys',value,id,'0','bug' from bugzilladb.op_sys;

# Bug  platform
insert into ptdb.traq_menus (menuname,display_value,value,project,rec_type) select 'bug_platform',value,id,'0','bug' from bugzilladb.rep_platform;

# version
insert into ptdb.traq_menus (menuname,display_value,value,project,rec_type) select 'version',value,value,product_id,'bug' from bugzilladb.versions;

# Bug resolution (first resolution in bugzilla is empty)
delete from ptdb.traq_menus where menuname='resolution' and rec_type='bug';
insert into ptdb.traq_menus (menuname,display_value,value,project,rec_type) select 'resolution',value,id,'0','bug' from bugzilladb.resolution where id>1;

# Milestones
alter table ptdb.traq_milestones modify milestoneid int(9) not null auto_increment;
insert into ptdb.traq_milestones (milestone,projectid,sortkey) select value,product_id,sortkey from bugzilladb.milestones;


# Bug priority 
delete from ptdb.traq_menus where menuname='priority' and rec_type like '%bug%';
insert into ptdb.traq_menus (menuname,display_value,value,project,rec_type) select 'priority',value,id,'0','bug' from bugzilladb.priority;

# Projects
insert into ptdb.traq_project (projectid,project,description,rec_types,url) select id,name,description,'bug',milestoneurl from bugzilladb.products;

# Components
insert into ptdb.traq_components (componentid,component,projectid,initialowner,initialqacontact,description,active,rec_type) select id,name,product_id,initialowner,initialqacontact,description,'checked','bug' from bugzilladb.components;

# Users
# modify some fields lengths to be compatible with what might be coming from bugzilla
alter table ptdb.logins modify username varchar(255);
alter table ptdb.logins modify password varchar(128);
delete from ptdb.logins where userid>1;
insert into ptdb.logins (username,userid,password,email,first_name,last_name,active,returnfields,bugtraqprefs,recordeditprivs,taskreturnfields,bugreturnfields,order1,order2,order3) select login_name,userid,cryptpassword,login_name,substring_index(realname,' ',1), trim(leading substring_index(realname, ' ',1) from realname), 'Yes','','','all','','','','','' from bugzilladb.profiles where userid>1;

# Groups
insert into ptdb.groups (groupname,description) select name,description from bugzilladb.groups;
insert into ptdb.groups (groupname,description) select concat(name, '-owners'), concat('Owners of ', name, ' group') from bugzilladb.groups;



#records
alter table ptdb.traq_records modify status_whiteboard mediumtext;
insert into ptdb.traq_records (record_id,type,assigned_to,severity,status,creation_ts,delta_ts,short_desc,bug_op_sys,priority,projectid,bug_platform,reporter,version,componentid,resolution,target_milestone,qa_contact,tech_contact,status_whiteboard,keywords) select b.bug_id,'bug',b.assigned_to,sev.id,stat.id,b.creation_ts,b.delta_ts,b.short_desc,op.id,pri.id,b.product_id,rep.id,b.reporter,b.version,b.component_id,res.id,mile.milestoneid,b.qa_contact,b.assigned_to,b.status_whiteboard,'' from bugzilladb.bugs b left join bugzilladb.bug_severity sev on b.bug_severity=sev.value left join bugzilladb.bug_status stat on b.bug_status=stat.value left join bugzilladb.op_sys op on b.op_sys=op.value left join bugzilladb.priority pri on b.priority=pri.value left join bugzilladb.rep_platform rep on b.rep_platform=rep.value left join bugzilladb.resolution res on b.resolution=res.value and res.id>1 left join ptdb.traq_milestones mile on b.product_id=mile.projectid and b.target_milestone=mile.milestone;

#long desc
insert into ptdb.traq_longdescs (record_id,who,thetext,date) select bug_id,who,thetext,bug_when from bugzilladb.longdescs;

# activity
insert into ptdb.traq_activity (record_id,who,fieldname,oldvalue,newvalue,tablename,date) select b.bug_id,b.who,f.name, b.removed,b.added,'traq_records',b.bug_when from bugzilladb.bugs_activity b left join bugzilladb.fielddefs f on b.fieldid=f.fieldid;

# do fieldname convertions
update ptdb.traq_activity set fieldname='severity' where fieldname='bug_severity';
update ptdb.traq_activity set fieldname='bug_platform' where fieldname='rep_platform';
update ptdb.traq_activity set fieldname='status' where fieldname='bug_status';
update ptdb.traq_activity set fieldname='projectid' where fieldname='product';
update ptdb.traq_activity set fieldname='componentid' where fieldname='component';
update ptdb.traq_activity set fieldname='bug_op_sys' where fieldname='op_sys';
# do data conversion for fields with different values/displayvalues now that they are managed in traq_menus
update ptdb.traq_activity a set oldvalue=(select distinct value from traq_menus m where a.fieldname=m.menuname and a.oldvalue=m.display_value and m.rec_type like '%bug%') where a.fieldname in (select distinct menuname from traq_menus);
update ptdb.traq_activity a set newvalue=(select distinct value from traq_menus m where a.fieldname=m.menuname and a.newvalue=m.display_value and m.rec_type like '%bug%') where a.fieldname in (select distinct menuname from traq_menus);
# add record creation activity entry
insert into ptdb.traq_activity (record_id,who,date,tablename,oldvalue,newvalue,fieldname) select record_id,reporter,creation_ts,'traq_records','New Record',record_id,'record_id' from ptdb.traq_records;

# cc
insert into ptdb.traq_cc select * from bugzilladb.cc;

# setup user group mapping and acl tables
# currently only adds all users to 'users' group and adds users group to all projects/components/records
insert into ptdb.user_groups select '3', userid from ptdb.logins;
insert into ptdb.acl_traq_projects select '3',projectid from ptdb.traq_project;
insert into ptdb.acl_traq_components select '3',componentid from ptdb.traq_components;
insert into ptdb.acl_traq_records select '3',record_id from ptdb.traq_records;







