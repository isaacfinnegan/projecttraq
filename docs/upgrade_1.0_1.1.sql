# modified traq_templates
# changing fieldname
alter table traq_templates change userid category VARCHAR(9);

# add visitor user, visitor user is added by default, but is not in any group
insert into logins (userid, first_name, last_name,username,  email,
                active, password)  values (
                0, "System", "Visitor", "visitor", "", "Yes", "");
