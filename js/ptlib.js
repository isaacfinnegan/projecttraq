function NewWindow(mypage, myname, w, h, scroll) {
	var winl = (screen.width - w) / 2;
	var wint = (screen.height - h) / 2;
	winprops = 'height='+h+',width='+w+',top='+wint+',left='+winl+',scrollbars='+scroll+',resizable'
	win = window.open(mypage, myname, winprops)
	if (parseInt(navigator.appVersion) >= 4) { win.window.focus(); }
};
function hoverOn(){
        this.className = 'tab tabHover';
}

function hoverOff(){
        this.className = 'tab';
}

function toggleTab(i){
        if (document.getElementById){
                for (f=1;f<numberOfTabs+1;f++){
                        document.getElementById('tabcontent'+f).style.display='none';
                        document.getElementById('tab'+f).className = 'tab';
	 		document.getElementById('tab'+f).onmouseover = hoverOn;
	 		document.getElementById('tab'+f).onmouseout = hoverOff;
                }
                document.getElementById('tabcontent'+i).style.display='block';
                document.getElementById('tab'+i).className = 'tab tabActive';
	 	document.getElementById('tab'+i).onmouseover = '';
	 	document.getElementById('tab'+i).onmouseout = '';
        }
}
function setStyleByClass(t,c,p,v)
{
	var elements;
	elements = document.getElementsByTagName(t);
	for(var i = 0; i < elements.length; i++){
		var node = elements.item(i);
		for(var j = 0; j < node.attributes.length; j++) {
			if(node.attributes.item(j).nodeName == 'class') {
				if(node.attributes.item(j).nodeValue == c) {
					eval('node.style.' + p + " = '" +v + "'");
				}
			}
		}
	}
}

function setdisplaysize(size,overflow,width)
{
	if(size==null || width==null)
	{
		size=GetCookie('commentsize') || '400';
		width=GetCookie('commentwidth') || '300';
		if(size=='auto')
		{
			overflow='visible';
		}
		else
		{
			overflow='auto';
		}
	}
	setStyleByClass('p','comments','height',size);
	setStyleByClass('p','comments','overflow',overflow);	
	setStyleByClass('p','comments','width',width);	
	SetCookie('commentsize',size);
	SetCookie('commentwidth',width);
}

function RTrim( value ) {
	var re = /((\s*\S+)*)\s*/;
	return value.replace(re, "$1");
	
}
function GetCookie (name) 
{  
	var arg = name + "=";  
	var alen = arg.length;  
	var clen = document.cookie.length;  
	var i = 0;  
	while (i < clen) 
	{    
		var j = i + alen;    
		if (document.cookie.substring(i, j) == arg)      
		return getCookieVal (j);    
		i = document.cookie.indexOf(" ", i) + 1;    
		if (i == 0) break;   
	}  
	return null;
}
function getCookieVal (offset) 
{  
	var endstr = document.cookie.indexOf (";", offset);  
	if (endstr == -1)    
	endstr = document.cookie.length;  
	return unescape(document.cookie.substring(offset, endstr));
}

function SetCookie (name, value) 
{  
	var argv = SetCookie.arguments;  
	var argc = SetCookie.arguments.length;  
	var expires = (argc > 2) ? argv[2] : null; 
	expires = new Date();
	expires.setFullYear(expires.getFullYear() +1 );
	var path = (argc > 3) ? argv[3] : null;  
	var domain = (argc > 4) ? argv[4] : null;  
	var secure = (argc > 5) ? argv[5] : false;  
	document.cookie = name + "=" + escape (value) + 
	((expires == null) ? "" : ("; expires=" + expires.toGMTString())) + 
	((path == null) ? "" : ("; path=" + path)) +  
	((domain == null) ? "" : ("; domain=" + domain)) +    
	((secure == true) ? "; secure" : "");
}
function loadIframe(iframeName, url) {
  if ( window.frames[iframeName] ) {
    window.frames[iframeName].location = url;   
    return false;
  }
  else return true;
}
function warnProjectChange() {
	alert("Changing projects will require you to resubmit with a new component.\nPlease refresh the form after submitting and choose a new component");
	return true;
}
function verify() {
	msg = "Please be sure to save edits before clicking this link.\nHit cancel to go back.";
	return confirm(msg);
}
function calendar(datefield){
  var val=escape(document.main.elements[datefield].value);
  window.open('../calpop.cgi?fld='+datefield+'&val='+val,'calendar','width=240,height=270,menubar=0,scrollbars=0,resizable=1,toolbar=0');
}
/* Check for Ext combobox and set otherwise just set the non Ext field info */
var userlookup={};
function setusername(userid,formfield,pre)
{
	// first get the username
	var username;
	if(document.getElementById('assigned_to').type!='hidden' && userlookup.length<2)
	{
		// from a lookup table created by parsing the assigned_to select
		for(i=0;i<recform.assigned_to.options.length;i++)
		{
			userlookup[recform.assigned_to.options[i].value]=recform.assigned_to.options[i].text;
		}
		username=userlookup[userid];
	}
	else
	{
		// or from the data source defined by the combofield for assigned_to
		username=userstore.getById(userid).get('text');
	}

	if(formfield=='assigned_to')
	{
		if(document.getElementById('assigned_to').type!='hidden' && userlookup.length<2)
		{
			document.getElementById('assigned_to').options[0].text='Default: '+username;
		}
		else
		{
			assigned_to_cmb.getEl().dom.value="Default: " + username;		
		}
	}
	else
	{
		document.getElementById(formfield+'_txt').innerHTML=username;
	}
}
function compselect(recform)
{
    var i;
   	var choice=recform.componentid.options[recform.componentid.selectedIndex].value;
   	if(choice)
   	{
        var comptech=components[choice][0];
        var compqa=components[choice][1];
        if(!recform.tech_contact.value)
        {
	        setusername(comptech,'tech_contact','Default: ');
        }
        if(!recform.assigned_to.value)
        {
	        setusername(comptech,'assigned_to','Default: ');
        }
        if(!recform.qa_contact.value)
        {
	        setusername(compqa,'qa_contact','Default: ');
        }
    }
    else
    {
        recform.tech_contact_cmb.value="";
        recform.assigned_to_cmb.value="";
        recform.qa_contact_cmb.value="";
    }
}
function validateTemplate(form) {
	if( form.templatename.value == "" ) {
		alert("Please enter a name for the template.");
		return false;
	}
	else {
		return true;
	}
}
function populateComps(form) {
        var selectedps = new Array();
        var xx = 0;
        for(var ii=0; ii < form.projectid.length; ii++) {
                if(form.projectid.options[ii].selected) {
                        selectedps[xx] = form.projectid.options[ii].value;
                        xx++;
                }
        }
        for(var xxx=0; xxx < 30; xxx++) {
                form.componentid.options[xxx] = null;
                form.version.options[xxx] = null;
        }
        var index1=0;
        var index2=0;
        for(var iii=0; iii < selectedps.length; iii++) {
                projectid = selectedps[iii];
                for(var i = 0; i < proj[projectid].length; i++) {
                        form.componentid.options[index1] = new Option(proj[projectid][i][0], proj[projectid][i][1]);
                        index1++;
                }
                for(var i=0; i < versions[projectid].length; i++) {
                        form.version.options[index2] = new Option(versions[projectid][i][0], versions[projectid][i][1]);
                        index2++;
                }
        }
}
function growrecord()
{
	var newsize=recsize+1;
	SetCookie('querysize',newsize);
	newsize=newsize + "px Lucida Grande, Geneva, Verdana, Arial, Helvetica, sans-serif";
	Ext.select('.recordrow',Ext.getDom('reclist')).setStyle('font',newsize);
	recsize=recsize+1;
}
function shrinkrecord()
{
	var newsize=recsize-1;
	SetCookie('querysize',newsize);
	newsize=newsize + "px Lucida Grande, Geneva, Verdana, Arial, Helvetica, sans-serif";
	Ext.select('.recordrow',Ext.getDom('reclist')).setStyle('font',newsize);
	recsize=recsize-1;
}
function setrecordsize()
{
	var size=GetCookie('querysize');
	if(size==null)
	{
		return;
	}
	newsize=size + "px Lucida Grande, Geneva, Verdana, Arial, Helvetica, sans-serif";
	setStyleByClass('a','record','font',newsize);
}

function dyn_menu (object, menu)
{
	var argv = dyn_menu.arguments;  
	var argc = dyn_menu.arguments.length;  
	var altmenu = (argc > 2) ? argv[2] : null; 
	var i,k,l,jj;
	var selections=[];
	var newmenu=[];
	var keys=[];
	// clear menu
	if(altmenu)
	{
    	menuobject=document.getElementById(altmenu);
	}
	else
	{
    	menuobject=document.getElementById(menu);
	}
	for (i = menuobject.options.length; i >= 0; i--) 
	{
		menuobject.options[i] = null; 
	}
	// build list of selected items from object
	i=0;
    for (var k=0;k < object.options.length;k++) {
        if (object.options[k].selected) {            
            selections[i]=object.options[k].value;
        	i++;
        }
    }
    // build hash of constructed menu options
    if(selections.length)
    {
    	k=0;
    	l=0;
    	for (i=0; i< selections.length; i++)
    	{
    		for(jj=0;jj<menuhash[menu][selections[i]].length;jj++)
    		{
    			if(newmenu[menuhash[menu][selections[i]][jj][0]])
    			{
    				newmenu[menuhash[menu][selections[i]][jj][0]]=newmenu[menuhash[menu][selections[i]][jj][0]] + "," + menuhash[menu][selections[i]][jj][1];
    			}
    			else
    			{
	    			newmenu[menuhash[menu][selections[i]][jj][0]]=menuhash[menu][selections[i]][jj][1];
	    			keys[l]=menuhash[menu][selections[i]][jj][0];
	    			l++;
    			}
	//			alert(menuhash[menu][selections[i]][jj][1]);
    		}
    	}
    	// now construct menu from hash
    	k=0;
    	keys.sort();
		for(jj=0;jj<keys.length;jj++)
		{
			menuobject.options[k]=new Option(keys[jj]);
			menuobject.options[k].value=newmenu[keys[jj]];
			k++;
		}    		
    }
}
function enableUserSelect(field)
{
	document.getElementById(field+'_disp').innerHTML='<i>Loading... </i><img src="../images/loading_small.gif">';
	if(userlistloaded)
	{

		document.getElementById(field+'_disp').style.display='none';
		document.getElementById(field+'_div').style.display='';
	}
	else
	{
		var url=userlisturl;
		var req=newxmlreq();
		req.onreadystatechange = function(obj)
		{
			if (req.readyState == 4) 
			{
				// only if "OK"
				if (req.status == 200) 
				{
					eval(req.responseText);
					userlistloaded=1;
					document.getElementById(field+'_div').style.display='';
					document.getElementById(field+'_disp').style.display='none';
					document.getElementById(field+'_fake').focus();
					document.getElementById(field+'_fake').select();
				} 
				else 
				{
					alert("There was an error retrieving the remote data");
				}
			}
		};
		req.open("GET", url, true);
		req.send("");
	}
}
// New quickview
var quickview;
function show_quickview(rec,qid,base)
{
	if(!quickview){
		quickview= new Ext.Window({
					width:600,
					height:450,
					shadow:true,
					title: 'Quickview',
					modal: false,
					closable:true,
					draggable:true,
					proxyDrag:false,
					autoScroll:true,
					deferredRender:false,
					closeAction:'hide'
			});
	}
	var url=base + "getRec.cgi?label=1&mode=getfields&fieldlist=short_desc,long_desc,assigned_to,reporter,status,priority,severity,projectid,target_date,target_milestone&delimiter=<br>&id="+rec;
	quickview.setTitle("Quickview for " + rec);
	if(quickview.hidden || !quickview.rendered)
	{
		quickview.show();
	}
	quickview.body.update('<img src="images/loading_small.gif"> Loading...');
	qv_showData2(rec,qid,base,quickview);
}

// NEW Bulk Editor
var bulkedit;
var bulk_data=false;
var checkall=false;

function show_bulkeditor()
{
	if(!bulkedit){
		bulkedit= new Ext.Window({
					width:700,
					applyTo:'bulkeditor',
					height:450,
					shadow:true,
					title: 'Bulk Editor',
					modal: false,
					closable:true,
					draggable:true,
					proxyDrag:false,
					autoScroll:true,
					fixedcenter:true
			});
	}
	bulkedit.show();
	var url="bulkeditor.cgi";
	var divid="bulk_form";
	if(bulk_data==false)
	{
		bulkloader(url,divid);
		bulkedit.body.appendChild(divid);
		bulk_data=true;
		Ext.get(Ext.DomQuery.select('input',Ext.getDom('reclist'))).setStyle('visibility','');
	}
}

function changesize( which )
{
	if(document.getElementById('comments-rzwrap'))
	{
		if(which==1)
		{
			commentarea.resizeTo(commentarea.width,(commentarea.resizeChild.getSize().height)+50)
		}
		else
		{
			if(commentarea.resizeChild.getSize().height>99)
			{
				commentarea.resizeTo(commentarea.width,(commentarea.resizeChild.getSize().height)-50)
			}
		}
	}
	else
	{
		size = GetCookie( pt_cookieCommentSize );
		if( size == null ){
			size=200; //default size
		}else{ // get size but strip off PX at end
			size = size.substr( 0, (size.length -2 ) );
		}
		size = parseInt( size );
		if( which == 1 ){ //increase
			size = size + 50;
		}else{ //decrease
			size = size - 50;
		}
		if( size >600 ){
			size = 600;
		}
		if( size < 150){
			size = 150;
		}
		size = size + "px";
		setCommentsDisplaySize( size );
	}
}

function initresize()
{
	// Dynamic field sizing
	var commentsizeinit = GetCookie( pt_cookieCommentSize );
	var notesizeinit = GetCookie( pt_cookieNoteSize );
	notefield = new Ext.Resizable('note', {
	wrap:true,
	width:660,
	height:notesizeinit,
	minWidth:660,
	maxWidth:660,
	minHeight: 50,
	dynamic:false
	});
	notefield.on("resize", storenotesize);
	commentarea = new Ext.Resizable('comments', {
	wrap:true,
	height:commentsizeinit,
	width:710,
	maxWidth:710,
	minWidth:710,
	minHeight: 100,
	dynamic:false
	});
	commentarea.on("resize", storecommentsize);
}




// NEW USER COMBO BOX  &   CC pulldown
var combofields=new Object();

function initcccombo(combofield)
{
	var ccombo;
	if(combofields[combofield])
	{
		// do nothing if the combo field has already been init'd
	}
	else
	{
		Ext.getDom('employees').value=Ext.getDom('ccinit').value;
//		combofields[combofield]=1;
		//setup cc store
		var tmp;
		var ccarr=new Array();
		for(tmp in grouplist)
		{
			ccarr.push([tmp,grouplist[tmp]]);
		}
		ccstore = new Ext.data.SimpleStore({
			fields: ['text', 'value'],
			data : ccarr
		});	
		var ccRec=Ext.data.Record.create(userstore.fields);
		userstore.each( function(r, i, len) {
			ccstore.add(new ccRec(r.data));
			});
		combofields[combofield] = new Ext.form.ComboBox({
			store: ccstore,
			displayField:'text',
			valueField:'value',
//			hiddenName: combofield,
			autoCreate:true,
			typeAhead: true,
			mode: 'local',
			triggerAction: 'all',
			selectOnFocus:true,
			blankText:'add...',
			minListWidth:170,
			forceSelection:true
		});
		combofields[combofield].on("select", addccrow);
		combofields[combofield].applyToMarkup(combofield);
		Ext.getDom('ccbox').innerHTML='';
		addccrow();
		Ext.getDom('ccinit').value='';
	}
}
var selectedcc=new Ext.util.MixedCollection(true);
function addccrow(){
	
 	numericUserId =  combofields['employees'].getValue();
	combofields['employees'].clearValue();
	if(numericUserId.search(/,/))
	{	
		tmparr=numericUserId.split(',');
 		for(k=0;k<tmparr.length;k++)
		{
			addcc(tmparr[k]);
		}
	}
	else
	{
		addcc(numericUserId);
	}
	// clear ccbox
	var ccbox=Ext.getDom('ccbox');
	if(ccbox.hasChildNodes)
	{
		for(var i=0;i<ccbox.childNodes.length;i++)
		{
			ccbox.removeChild(ccbox.childNodes[i]);
		}
	}
	selectedcc.keySort('ASC',function(a,b){if(a<b){return -1;} return 1;});
	selectedcc.each(function(r){ ccbox.appendChild(r) } )
	combofields['employees'].focus();
	return;
}
function addcc(num){
	if(userstore.getById(num))
	{
		if(selectedcc.containsKey(userstore.getById(num).get('text')))
		{
			return;
		}
		else
		{
			var newchk=document.createElement('div');
			newchk.className='ccrow';
			newchk.innerHTML='<label><input type=checkbox name=cc id=cc value='+num+' checked>'+userstore.getById(num).get('text')+'</label>';		
			selectedcc.add(userstore.getById(num).get('text'),newchk);
		}
	}
}

function applycombo(combofield)
{
	var fieldval=Ext.getDom(combofield).value;
	// setup combo
	combofields[combofield] = new Ext.form.ComboBox({
		store: userstore,
		displayField:'text',
		valueField:'value',
		autoCreate:true,
		typeAhead: true,
		mode: 'local',
		triggerAction: 'all',
		selectOnFocus:true,
		forceSelection:true
	});
	// flip displays for text value and show input field
	Ext.getDom(combofield+'_txt').style.display='none';
	Ext.getDom(combofield+'_disp').style.display='';
	combofields[combofield].applyToMarkup(combofield+'_disp');
	combofields[combofield].on('select',function (){ Ext.get(combofield).dom.value=combofields[combofield].getValue(); });
	combofields[combofield].setValue(fieldval);
	combofields[combofield].fireEvent('select');
	combofields[combofield].focus();
	return combofields[combofield];
}

// END NEW COMBO BOX


function resolutionduplicate(form)
{
	if(form.resolution.value==duplicateresolution)
        {
                var dup;
                dup=window.prompt("Enter duplicate record #","");
                var exp = new RegExp(/^[bBtT]/i);
                var dup = dup.replace( exp, '') ;
                if (dup == [[RECORD_ID_VAL]])
                {
                        alert ("Record cannot be marked as a Duplicate of itself.");
                        return false;
                }
                else
                {
                        form.note.value="---Marked duplicated of B" + dup + " ---\n" + form.note.value;
                        form.note.focus();
                }
        }
}

function storenotesize()
{
	SetCookie(pt_cookieNoteSize,notefield.resizeChild.getSize().height);
}
function storecommentsize()
{
	SetCookie(pt_cookieCommentSize,commentarea.resizeChild.getSize().height);
}

function clone(link,form)
{
	var url=genUrlFromForm(link,form);
	window.location.assign(url);
}
function genUrlFromForm(link,form)
{
	var i;
	var k;
	var querystring='';
	var url;
	for(i=0;i<form.elements.length;i++)
	{
        if(form.elements[i])
        {
            if( form.elements[i].type=='radio' 
                || form.elements[i].type=='checkbox' 
                || form.elements[i].type=='select-one'
                || form.elements[i].type=='select-multiple')
            {
                if(form.elements[i].type=='radio' 
                || form.elements[i].type=='checkbox')
                {
                    var checkbox=form.elements[i].name;
                    if(form.elements[i].checked)
                    {
                        querystring=querystring + ";" +form.elements[i].name + '=' + encodeURI(form.elements[i].value);
                    }
                }
                else
                {
                    for(k=0;k<form.elements[i].options.length;k++)
                    {
                        if(form.elements[i].options[k].selected)
                        {
                            querystring=querystring + ";" +form.elements[i].name + '=' + encodeURI(form.elements[i].options[k].value);
                        }
                    }
                }
            }
            else
            {
                if(form.elements[i].type!='button' 
                    && form.elements[i].type!='file'
                    && form.elements[i].type!='reset'
                    && form.elements[i].type!='submit')
                {
                    querystring=querystring + ";" +form.elements[i].name + '=' + encodeURI(form.elements[i].value);
                }
            }
        }
	}
	url=link+querystring
	return url;
}
function attachmentAdd(form) {
        if(form.long_desc)
        {
            form.long_desc.value="---Attachment Added---\n" + form.long_desc.value;
            form.long_desc.focus();
        }
        if(form.note)
        {
            form.note.value="---Attachment Added---\n" + form.note.value;
            form.note.focus();
        }
        return true;
}
function dependencyInput (inputvalue)
{
        var charpos = inputvalue.search("[^BbTt0-9,]");
        if(inputvalue.length > 0 &&  charpos >= 0)
        {
                alert ("Please enter a valid record # ");
        }
        return true;
}
function checkall(field) 
{
	checkall=true;
	if (checkflag == "false") 
	{
		for (i = 0; i < field.length; i++) 
		{
			field[i].checked = true;
			field[i].style.visibility='';
		}
		checkflag = "true";
		return "Uncheck All"; 
	}
	else 
	{
		for (i = 0; i < field.length; i++) 
		{	
			field[i].checked = false; 
			field[i].style.visibility='';
		}
		checkflag = "false";
		return "Check All"; 
	}
}
function toggle(toggle,queryid)
{
    var i,ii;
	var mode='';
	var recnum=toggle.id.replace(/gif/,"");
	if(toggle.src.match('plus.gif'))
	{
		mode='expand';
	}
	if(toggle.src.match('minus.gif'))
	{
		mode='collapse';
	}
	if(mode=='expand')
	{
		toggle.src=baseurl+'/images/minus.gif';
		lineagecheck=lineagecheck + '-' + recnum + '-';
	}
	if(mode=='collapse')
	{
		toggle.src=baseurl+'/images/plus.gif';
		lineagecheck=lineagecheck.replace(RegExp('-' + recnum + '-','g'),'');
	}
	redrawtable(queryid);
}
function expandall(queryid)
{
    var ii;
    lineagecheck='-' + recordlist.join('--') + '-';
   
    for(ii=0;ii<recordlist.length;ii++)
    {
        if(document.getElementById("gif"+recordlist[ii]))
        {
            document.getElementById("gif"+recordlist[ii]).src=baseurl+'/images/minus.gif';
        }
    }
    redrawtable(queryid);
}
function collapseall(queryid)
{
    var ii;
    lineagecheck='';
//     for(ii=0;ii<recordlist.length;ii++)
//     {
//         if(document.getElementById(recordlist[ii]))
//         {
//             document.getElementById("gif"+recordlist[ii]).src=baseurl+'/plus.gif';
//         }
//     }
    for(ii=0;ii<recs.length;ii++)
    {
    	if(document.getElementById("gif"+recs[ii]))
    	{
            document.getElementById("gif"+recs[ii]).src=baseurl+'/images/plus.gif';    	
    	}
    }
    redrawtable(queryid);
}
function inittable(queryid)
{
	lineagecheck=GetCookie('hierstate');
	var arr=[];
	var ii;
	if(lineagecheck)
	{
		arr=lineagecheck.split('-');
        for(ii=0;ii<arr.length;ii++)
        {
            if(arr[ii] && (document.getElementById("gif"+arr[ii])!=null) )
            {
                document.getElementById("gif"+arr[ii]).src=baseurl+'/images/minus.gif';
            }
        }
	}
	else
	{
        lineagecheck='-' + recordlist.join('--') + '-';	   
        for(ii=0;ii<recordlist.length;ii++)
        {
            if(document.getElementById("gif"+recordlist[ii]))
            {
                document.getElementById("gif"+recordlist[ii]).src=baseurl+'/images/minus.gif';
            }
        }
	}
	redrawtable(queryid);
}
function redrawtable(queryid)
{
	if( ! lineagecheck)
	{
		lineagecheck='';
	}
	v = document.getElementById("queryresults"+queryid);
    var state=0;
    var hide=0;
    var oddrow=0;
    var match=0;
    for (i=0; i < v.rows.length; i++)
    {
    	var lineage=v.rows[i].id.split('-');
    	for(ii=0;ii<lineage.length;ii++)
    	{
    		if( lineagecheck.match(lineage[ii])  )
    		{
    			state++;
    		}
    	}
    	if(state==lineage.length)
    	{
			v.rows[i].style.display="";
			if( v.rows[i].childNodes[1].id != "" ){
				recs.push(v.rows[i].childNodes[1].id);
			}
		}
		else
		{
			v.rows[i].style.display="none";
		}
		if( ! v.rows[i].id )
		{
			v.rows[i].style.display="";
		}
		v.rows[i].className=v.rows[i].className.replace(/odd/,' ');
		if(v.rows[i].style.display=="" && oddrow>0 && i>0)
		{
			v.rows[i].className+=' odd';
			oddrow=0;	
		}
		else
		{
			if(v.rows[i].style.display=="" && i>0)
			{
				oddrow++;
			}
		}
		state=0;
		check=0;
		hide=0;
    }
    SetCookie('hierstate',lineagecheck);
}

function bulkloader(url,divid)
{

    var req=newxmlreq();
    req.onreadystatechange = function(obj)
    {
        if (req.readyState == 4) 
        {
            // only if "OK"
            if (req.status == 200) 
            {
                eval(req.responseText);
            } 
            else 
            {
                document.getElementById(divid).innerHTML=("There was a problem retrieving the data:\n" +
                req.statusText);
            }
        }
    };
    req.open("GET", url, true);
    req.send("");
}
function activityloader(url,divid)
{
    if(activitydata==false)
    {
        var req=newxmlreq();
        req.onreadystatechange = function(obj)
        {
            if (req.readyState == 4) 
            {
                // only if "OK"
                if (req.status == 200) 
                {
                        document.getElementById(divid).innerHTML=req.responseText;
                } 
                else 
                {
                    document.getElementById(divid).innerHTML=("There was a problem retrieving the log data:\n" +
                    req.statusText);
                }
            }
        };
        req.open("GET", url, true);
        req.send("");
        activitydata=true;
    }
}

function js_divloader(url,divid)
{
        var req=newxmlreq();
        req.onreadystatechange = function(obj)
        {
            if (req.readyState == 4) 
            {
                // only if "OK"
                if (req.status == 200) 
                {
                        document.getElementById(divid).innerHTML=req.responseText;
                } 
                else 
                {
                    document.getElementById(divid).innerHTML=("There was a problem retrieving the data:\n" +
                    req.statusText);
                }
            }
        };
        req.open("GET", url, true);
        req.send("");
}

function js_varloader(url,aaa)
{
        var req=newxmlreq();
        req.onreadystatechange = function(obj)
        {
            if (req.readyState == 4) 
            {
                // only if "OK"
                if (req.status == 200) 
                {
                        aaa=req.responseText;
                } 
                else 
                {
                    aaa=("There was a problem retrieving the data:\n" +
                    req.statusText);
                }
            }
        };
        req.open("GET", url, true);
        req.send("");
}


function divload()
{


    this.data=false;
//  These variables need to be set before any of the methods in the object can be run
//    this.urlreq
//    this.area
//    this.loadinghtml
    this.evalreturn=false;
    this.processChange = function(obj)
    {
        if (req.readyState == 4) 
        {
            // only if "OK"
            if (req.status == 200) 
            {
                if(divloader.evalreturn)
                {
                    eval(req.responseText);
                }
                else
                {
                    divloader.area.innerHTML=req.responseText;
                    divloader.data=true;
//                    alert(testvar);
                }
            } 
            else 
            {
                alert("There was a problem retrieving the log data:\n" +
                req.statusText);
            }
        }
    };
    this.gethtml=function(obj)
    {
        if(!divloader.data)
        {
            divloader.area.innerHTML=divloader.loadinghtml;
            xmlreq(obj.urlreq,obj);
        }
    };
}

function newxmlreq() {
    var req;
	req = false;
    // branch for native XMLHttpRequest object
    if(window.XMLHttpRequest) {
    	try {
			req = new XMLHttpRequest();
        } catch(e) {
			req = false;
        }
    // branch for IE/Windows ActiveX version
    } else if(window.ActiveXObject) {
       	try {
        	req = new ActiveXObject("Msxml2.XMLHTTP");
      	} catch(e) {
        	try {
          		req = new ActiveXObject("Microsoft.XMLHTTP");
        	} catch(e) {
          		req = false;
        	}
		}
    }
    return req;
}
function xmlreq(url,obj) {
    var req=newxmlreq();
	if(req) {
        //'this value is ignored, but the step is necessary
        //req.setRequestHeader "Cookie", "any non-empty string here"
        //'set all cookies here
        //req.setRequestHeader "Cookie", "cookie1=value1; cookie2=value2"
        req.onreadystatechange = obj.processChange;
		req.open("GET", url, true);
		req.send("");
	}
}

function xmlreqsync(url) {
    var req=newxmlreq();
	if(req) {
        //'this value is ignored, but the step is necessary
        //req.setRequestHeader "Cookie", "any non-empty string here"
        //'set all cookies here
        //req.setRequestHeader "Cookie", "cookie1=value1; cookie2=value2"
		req.open("GET", url, false);
		req.send(null);
        		
		return req.responseText;
	}
}

function addField (form, fieldType, fieldName, fieldValue) {
  if (document.getElementById) {
    var input = document.createElement('INPUT');
      if (document.all) { // what follows should work 
                          // with NN6 but doesn't in M14
        input.type = fieldType;
        input.name = fieldName;
        input.value = fieldValue;
      }
      else if (document.getElementById) { // so here is the
                                          // NN6 workaround
        input.setAttribute('type', fieldType);
        input.setAttribute('name', fieldName);
        input.setAttribute('value', fieldValue);
      }
    form.appendChild(input);
  }
}

function getRecordList()
{
    var ii,idstr;
    var idlist=[];
    for(ii=0;ii<document.reclist.ids.length;ii++)
    {
      if(document.reclist.ids[ii].checked)
      {
        idlist.push(document.reclist.ids[ii].value);
       }
    }
    idstr=idlist.join(',');
    return idstr;
    
}

function showField(field,instant)
{
        document.getElementById(field+'queryfield').className='queryfieldused';
        document.getElementById('queryarea').appendChild(document.getElementById(field+'area'));
        if(instant)
        {
            document.getElementById(field + 'area').style.display='block';
        }
        else
        {
            Ext.get(field + 'area').fadeIn();
            fieldareas.push(field);
            document.getElementById('fieldarealist').value=fieldareas.join('--');
        }
}
function hideField(field,fade)
{
        var ii;
        if(document.getElementById(field+'queryfield'))
        {
            document.getElementById(field+'queryfield').className='queryfield';
            if(fade=='nofade')
            {
                document.getElementById(field+'area').style.display='none';
            }
            else
            {
                Ext.get(field + 'area').fadeOut({useDisplay:true});
            }
            for(ii=0;ii<fieldareas.length;ii++)
            {
                if(fieldareas[ii]==field)
                {
                    break;
                }
            }
            fieldareas.splice(ii,1);
            document.getElementById('fieldarealist').value=fieldareas.join('--');
            clearField(field);
        }
}
function clearField(fieldname)
{
    var h=0;
    var field=document.getElementById(fieldname);
    if(document.getElementById(fieldname))
    {
        if(field.type=='text' || field.type=='textarea')
        {
            field.value='';
        }
        if(field.type=='select' || field.type=='select-one')
        {
            field.selectedIndex=null;
        }
        if(field.type=='select-multiple')
        {
            for(h=0;h<field.options.length;h++)
            {
                field.options[h].selected=null;
            }
        }
        if((field.type=='checkbox' || field.type=='radio') && field.options)
        {
            for(h=0;h<field.options.length;h++)
            {
                field.options[h].checked=null;
            }
        }
    }
    if(document.getElementById(fieldname + 'group'))
    {
        clearField(fieldname+'group');
    }
    if(document.getElementById('end_' + fieldname))
    {
        clearField('end_' + fieldname);
    }
    if(document.getElementById('start_' + fieldname))
    {
        clearField('start_' + fieldname);
    }
}
var tooltipfetch=new Array;

function getTooltip(id,url,owner)
{
    if(tooltipfetch[id])
    {
        return;
    }
    else
    {
        tooltipwrite(id,url);
        tooltipfetch[id]=1;
    }
}
function tooltipwrite(divid,url) {

    var req=newxmlreq();
	if(req) {
        req.onreadystatechange = function() {
            if (req.readyState==4) {
                if (req.status==200)
                {
                    if(document.getElementById(divid))
                    {
                        domTT_update(divid,req.responseText);
                    }
                }                
                else
                    return null;
            }
            return null;
        };
		req.open("GET", url, true);
		req.send("");
	}
}

// --------------------------------
// Record Quick View routines below
// --------------------------------

function qv_showData2( recnum, queryid ,base,window ){
		
		var req=newxmlreq();
        req.onreadystatechange = function(obj)
        {
            if (req.readyState == 4) 
            {
                // only if "OK"
                if (req.status == 200) 
                {
						resultstr = req.responseText; 
						var results=resultstr.split("::");
							tablestr= "<table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" class=\"qv_table\" width=\"100%\">";
							tablestr += "<tr><td align=\"right\" valign=\"top\" nowrap=\"nowrap\"><b>Record</b></td><td valign=\"top\">: <b style=\"font-size:9pt;\"><a href=\"/projecttraq/redir.cgi?id="+recnum+"&queryid="+queryid+"\">#"+recnum+"</a></b></td></tr>";
						
						for( i=0; i<results.length; i++ ){
							datastr=results[i];
							splitloc= datastr.indexOf(':'); // get first location 
							title =datastr.substr( 0,splitloc );
							data = datastr.substr( splitloc );
							data = RTrim(data);
							if( title == "" ){ title = "&nbsp;"; }
							if( data == "" ){ data = "&nbsp;"; }
							if( title != "&nbsp;" || data != "&nbsp;" ){
								tablestr += "<tr><td width=\"100\" align=\"right\" valign=\"top\" nowrap=\"nowrap\"><b>"+title+"</b></td><td valign=\"top\">"+data+"</td></tr>";
							}
						}
						tablestr += "</table>";
						window.body.update(tablestr);
                } 
                else 
                {
                    alert("There was a problem retrieving the Record data:\n" +
                    req.statusText);
                }
            }
        };
		url=base + "getRec.cgi?label=1&mode=getfields&fieldlist=short_desc,long_desc,assigned_to,reporter,status,priority,severity,projectid,target_date,target_milestone&delimiter=::&id="+recnum;
        req.open("GET", url, true);
        req.send("");
	}
	
// Record Quick View routines above




function getElementsByClassName(oElm, strTagName, strClassName){
    var arrElements = (strTagName == "*" && oElm.all)? oElm.all : oElm.getElementsByTagName(strTagName);
    var arrReturnElements = new Array();
    strClassName = strClassName.replace(/\-/g, "\\-");
    var oRegExp = new RegExp("(^|\\s)" + strClassName + "(\\s|$)");
    var oElement;
    for(var i=0; i<arrElements.length; i++){
        oElement = arrElements[i];      
        if(oRegExp.test(oElement.className)){
            arrReturnElements.push(oElement);
        }   
    }
    return (arrReturnElements)
}

// PT Edit task/bug cookie code

function setCommentsDisplaySize( size ){
	if(document.getElementById('comments-rzwrap'))
	{
		document.getElementById('comments-rzwrap').style.height=size;
		document.getElementById('comments-rzwrap').style.height=size-2;
	}
	else
	{
		document.getElementById('comments').style.height=size;
	}
	SetCookie(pt_cookieCommentSize,size);
}


function toggleactivities( nosetcookie ){

	if( document.getElementById("activitytext").innerHTML=="Show Activities" ){ //was hide so now show
		document.getElementById("activitytext").innerHTML = "Hide Activities";
		//show all activities toggle them on 
		for( i=0; i< changesElements.length; i++){
			changesElements[i].style.display = "block";
		}
		if( nosetcookie == "" ){
			SetCookie(pt_cookieActivities,"1");
		}
	}else{ // was show--- so now hide all activities
		document.getElementById("activitytext").innerHTML="Show Activities";
		// now hide all activities
		for( i=0; i< changesElements.length; i++){
			changesElements[i].style.display = "none";
		}
		if( nosetcookie == "" ){
			SetCookie(pt_cookieActivities,"0");
		}
	}
	// scroll div to top
	document.getElementById("comments").scrollTop="0";
	return;
}
    	var ua = window.navigator.userAgent
    	var msie = ua.indexOf ( "MSIE " )
		ie = false;
    	if ( msie > 0 ){    // is Microsoft Internet Explorer;
        	ie= true;
		}


// CC list routines
// turn off ALL CC elements by default except those that are checked
	// every CC element is wrapped by label and LI therefore we need to go 2 parents up
	// to toggle display of corresponding LI
	// <li><label><input type=checkbox name=cc value="5538">Aasmeet Goda</label></li>
	function makeCCsInvis(){
		
		// are we in IE or other

		var ccs=document.getElementsByName("cc");
		for( i=0; i<ccs.length; i++ ){
			// HIDE NON_CHECKED OPTIONS
			// IE method here as IE defaults all CHECKED to be false unless explicitly set
			if( ie == true ){
				if( ccs[i].getAttribute("checked") == false ){ // these are plain UNCHECKED names
					labelElement= ccs[i].parentNode;
					liElement = labelElement.parentNode;
					liElement.style.display="none";
				}
			}
			
			// FF - non IE method
			if( ie == false ){
				if( ccs[i].getAttribute("checked")!="" ){ // only hide NON-checked values - works in FF
					labelElement= ccs[i].parentNode;
					liElement = labelElement.parentNode;
					liElement.style.display="none";
				}
			}
		}
	}
	
	
	 var userList = "";
 	function genUserList(){ //generate dynamic array of users
      	// we get the names from the assign_to select...because 
      	// the actual CC list is checboxes so we cannot access the textual labels
     	var names=document.main2.assigned_to;
     	for( i=0; i< names.options.length; i ++ ){
       		if( names.options[i].text != "" ){
           		userList =  userList + "\""+names.options[i].text+"\"";
	           	if( i < (names.options.length-1)){
    	            userList=userList+",";
        	   	}
       		}
     	}
	}
	
	function getUserIdFromName( name ){
	 	var names=document.main2.assigned_to;
     	for( i=0; i< names.options.length; i ++ ){
		 	if( names.options[i].text == name ){
				return names.options[i].value;
			}
     	}
		return 0;
	}
	

var isDOM = (document.getElementById ? true : false);
var isIE4 = ((document.all && !isDOM) ? true : false);
var isNS4 = (document.layers ? true : false);
var isNS = navigator.appName == "Netscape";
 
function getRef(id) {
	if (isDOM) return document.getElementById(id);
	if (isIE4) return document.all[id];
	if (isNS4) return document.layers[id];
}
function initcombos()
{
	assigned_to_cmb = new Ext.form.ComboBox({
			typeAhead: true,
			triggerAction: 'all',
			transform:'assigned_to',
			selectOnFocus: true,
			forceSelection:true
		});
	userstore=assigned_to_cmb.store;
	assigned_to_cmb.on('select',resetuserstore);
	ccstore;
	initcccombo('employees');
	Ext.getDom('short_desc').focus();

}
function resetuserstore()
{
	userstore.filter('','');
}

// Field selection Dialog box
var qfdialog;
function showQFdialog(path,type,initset,qftitle,handler)
{
	if(!qfdialog)
	{
		var qfarea=setupfieldlistlayout('fieldselections',path,type,initset);
		qfdialog=new Ext.Window({
				title: qftitle,
				modal:true,
//				width:430,
//				height:300,
				autoWidth:true,
				autoHeight:true,
				minWidth:430,
				minHeight:300,
// 				items:[
// 					qfarea
// 				]
		
			});
		qfdialog.addButton('Close', qfdialog.hide, qfdialog);
		qfdialog.addButton('Update', function() {  handler.call() });
 		qfdialog.add(qfarea);
	}
	qfdialog.show();
}

// setup for field selection layout and 2 trees.  used by prefs/query/quickfields
var tree;
var tree2;
function getQFselections()
{
	var tmparr=new Array();
	var tmpnode;
	tmpnode=tree2.getRootNode().firstChild;
	tmparr.push(tmpnode.id);
	while(tmpnode=tmpnode.nextSibling)
	{
	    tmparr.push(tmpnode.id);
	}
	return tmparr.join(',');
}
function setupfieldlistlayout(el,cgipath,rectype,initset)
{
	var fieldds=new Ext.data.Store({
		root: 'fields',
		proxy: new Ext.data.HttpProxy({
			url: cgipath,
			method: 'GET',
			params: {type:rectype}
		}),
		reader: new Ext.data.JsonReader({
			root: 'fields',
			id: 'value'
			},
			[ 'label','value']
		)
	});
	var selectedfields=new Ext.util.MixedCollection(true);
	var layout= new Ext.Panel({
		applyTo: el,
		layout: 'border',
		items:[
		{
			region: 'center',
			width: 200,
			titlebar:true,
			title: 'Fields (drag to the right)',
			autoScroll:true
		},
		{
			region: 'east',
			width: 200,
			titlebar:true,
			title: 'Selection',
			autoScroll:true
		}]
	});
	console.log(layout.getLayout().center.el.dom.id);
	var Tree=Ext.tree;

	tree = new Tree.TreePanel( {
		el: layout.getLayout().center.el,
		enableDD:true,
		containerScroll: true,
		rootVisible:false
	});
				
	// set the root node
	var root = new Tree.AsyncTreeNode({
		text: 'Field list', 
		draggable:false, // disable root node dragging
		id:'fieldlist'
	});
	tree.setRootNode(root);

	// render the tree
	tree.render();
	

	tree2 = new Tree.TreePanel( {
		el: layout.getLayout().east.el,
		containerScroll: true,
		enableDD:true,
		rootVisible:false
	});
	
	// add the root node
	var root2 = new Tree.AsyncTreeNode({
		text: 'Field Selections', 
		draggable:false, 
		id:'selectedfields'
	});
	tree2.setRootNode(root2);
	//tree2.render();
	
	fieldds.on('load',function(){
		fieldds.each( function(r) {
			tree.getRootNode().appendChild( new Ext.tree.TreeNode({
				text: r.get('label'),
				id: r.get('value') ,
				iconCls:'emptyIcon',
				leaf:true
			}) );	
		});
		if( initset=='')
		{
			initset='status,short_desc,assigned_to';
		}
		var initfields=initset.split(',');
		for(var ii=0; ii < initfields.length; ii++)
		{
				var tmpnode=tree.getRootNode().removeChild(tree.getNodeById(initfields[ii]));
				tree2.getRootNode().appendChild(  tmpnode );		
		}
//		tree2.getSelectionModel().init(tree2);
		tree2.render();
	});
	fieldds.load();
	return layout;
}


// Notice alert
Ext.Notice = function(){
    var msgCt;

    function createBox(t, s){
        return ['<div class="msg">',
                '<div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>',
                '<div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc"><h3>', t, '</h3>', s, '</div></div></div>',
                '<div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>',
                '</div>'].join('');
    }
    return {
        msg : function(title, format){
            if(!msgCt){
                msgCt = Ext.DomHelper.insertFirst(document.body, {id:'msg-div'}, true);
            }
            msgCt.alignTo(document, 't-t');
            var s = String.format.apply(String, Array.prototype.slice.call(arguments, 1));
            var m = Ext.DomHelper.append(msgCt, {html:createBox(title, s)}, true);
            m.slideIn('t').pause(3).ghost("t", {remove:true});
        }
    };
}();
