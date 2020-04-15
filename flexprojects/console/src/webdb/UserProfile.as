package webdb
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Form;
	import mx.containers.FormItem;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.DataGrid;
	import mx.controls.TextInput;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.ClassFactory;
	import mx.resources.ResourceManager;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.soap.Operation;
	import mx.rpc.soap.WebService;
	
	import oblik.basetype.OblikCharacter;
	import oblik.basetype.OblikLogical;
	import oblik.basetype.OblikLogicalBr;
	
	public class UserProfile extends Object
	{
        public var isnew:Boolean;
        public var login:TextInput;
        public var username:TextInput;
        public var isnewpass:CheckBox;
        public var confpass:TextInput;
        public var newpass:TextInput;
        public var oldpass:TextInput;
        public var email:TextInput;
        public var ent:TextInput;
        public var cathg:TextInput;
        public var isbanned:CheckBox;
        public var dg:DataGrid;
        public var bSave:Button;
        public var dp:ArrayCollection;
        public var ds:ArrayCollection;
        public var dbi:Object;
        public var rootBox:VBox;
        private var srv:WebService; 
        private var ContextId:String; 
        private var UserProfileoper:Operation;
        private var SaveProfileoper:Operation;
		
		public function UserProfile()
		{
			super();
           	srv = new WebService();
			UserProfileoper = new Operation(null, "UserProfile");
			UserProfileoper.addEventListener(ResultEvent.RESULT, OnUserProfile, false, 0, true);
			UserProfileoper.addEventListener(FaultEvent.FAULT, Onfault, false, 0, true);
			SaveProfileoper = new Operation(null, "SaveProfile");
			SaveProfileoper.addEventListener(ResultEvent.RESULT, OnSaveProfile, false, 0, true);
			SaveProfileoper.addEventListener(FaultEvent.FAULT, Onfault, false, 0, true);
			srv.operations = [UserProfileoper,SaveProfileoper];
		}
		private function resourceManager (messname:String):String
		{
			return ResourceManager.getInstance().getString('Console',messname);
		}
        private function Onfault(event:FaultEvent):void
        {
            Alert.show(event.fault.faultString, resourceManager('ConnectionError'));
        }
        private function OnUserProfile(event:ResultEvent):void
        {
          	this.dp = event.result.UserProfile;
          	this.ds = event.result.AvailServices;
          	this.dbi = event.result.UserProfile.list.source[0];
          	if (dp.length > 0)
          	{
          		login.text = dbi.UserLogin;
          		username.text = dbi.UserName;
          		email.text = dbi.UserEMail;
          		ent.text = dbi.UserCompany;
          		cathg.text = dbi.UserPosition;
          		isbanned.selected = dbi.UserBanned;
          	}
  			dg.dataProvider = ds;
			if (ds.length < 300)
       			dg.height = ds.length * 26 + 48;
			else
				dg.height = 600;
        }
        public function addUserProfileTab(isAdmin:Boolean, IsNew:Boolean, iReadOnly:Boolean, servicepath:String, iContextId:String, UserLogin:String):VBox 
        {
			srv.wsdl = servicepath;
			ContextId = iContextId;
			srv.loadWSDL();
			isnew = IsNew;
       		UserProfileoper.send (ContextId, IsNew, UserLogin);
  				
  			var newVBox:VBox = new VBox();
  			var newHBox:HBox = new HBox();
  			var newHBox2:HBox = new HBox();
  			var newVBox2:VBox = new VBox();
  			var newform:Form = new Form ();

			var fi:FormItem = new FormItem();
			fi.label = resourceManager('ProfileLogin')+':';
  			var ti:TextInput = new TextInput();
  			ti.width = 200;
  			ti.editable = IsNew && ! iReadOnly;
  			fi.addChild(ti);
  			this.login = ti;
  			newform.addChild (fi);
  			newVBox2.addChild(newform);
  			fi = new FormItem();
  			fi.label = resourceManager('ProfileUserName')+':';
  			ti = new TextInput();
  			ti.editable = ! iReadOnly;
  			ti.width = 500;
  			fi.addChild(ti);
  			this.username = ti;
  			newform.addChild (fi);

  			fi = new FormItem();
  			var cb:OblikLogical = new OblikLogical();
  			cb.ReadOnly = iReadOnly;
  			cb.label = resourceManager('ProfileChangePassword');
	    	cb.addEventListener(Event.CHANGE, OnChangePass );	
    		cb.addEventListener(KeyboardEvent.KEY_UP, OnChangePass2);
  			fi.addChild(cb);
  			this.isnewpass = cb;
  			newform.addChild (fi);
  			fi = new FormItem();
  			fi.label = resourceManager('ProfileOldPassword')+':';
  			ti = new TextInput();
  			ti.width = 200;
  			ti.enabled = false;
  			ti.displayAsPassword = true;
  			fi.addChild(ti);
  			this.oldpass = ti;
  			newform.addChild (fi);
  			fi = new FormItem();
  			fi.label = resourceManager('ProfileNewPassword')+':';
  			ti = new TextInput();
  			ti.width = 200;
  			ti.enabled = false;
  			ti.displayAsPassword = true;
  			fi.addChild(ti);
  			this.newpass = ti;
  			newform.addChild (fi);
  			fi = new FormItem();
  			fi.label = resourceManager('ProfileConfPassword')+':';
  			ti = new TextInput();
  			ti.width = 200;
  			ti.enabled = false;
  			ti.displayAsPassword = true;
  			fi.addChild(ti);
  			this.confpass = ti;
  			newform.addChild (fi);
  				
  			fi = new FormItem();
  			fi.label = resourceManager('ProfileEMail')+':';
  			ti = new TextInput();
  			ti.editable = ! iReadOnly;
  			ti.width = 500;
  			fi.addChild(ti);
  			this.email = ti;
  			newform.addChild (fi);
  			fi = new FormItem();
  			fi.label = resourceManager('ProfileCompany')+':';
  			ti = new TextInput();
  			ti.editable = ! iReadOnly;
  			ti.width = 500;
  			fi.addChild(ti);
  			this.ent = ti;
  			newform.addChild (fi);
  			fi = new FormItem();
  			fi.label = resourceManager('ProfilePosition')+':';
  			ti = new TextInput();
  			ti.editable = ! iReadOnly;
  			ti.width = 500;
  			fi.addChild(ti);
  			this.cathg = ti;
  			newform.addChild (fi);
  			fi = new FormItem();
  			cb = new OblikLogicalBr();
/*  			cb.ReadOnly = iReadOnly; */
  			cb.label = resourceManager('ProfileBanned');
    		this.isbanned = cb;
  			fi.addChild(cb);
  			if (isAdmin == true)
  			{
  				newform.addChild (fi);
  			}
  			
  			fi = new FormItem();
  			fi.label = resourceManager('ProfileServices');
			newform.addChild (fi);
   			var dgc:DataGridColumn;
   			var aColumnsNew:Array = new Array;
			var or:Object = new Object ();
			var cf:ClassFactory;
			or["ReadOnly"] = iReadOnly;
  			if (isAdmin == true)
   			{  
				dgc = new DataGridColumn();                                  
   				dgc.width = 100;
   				dgc.dataField = "Enabled";     
   				dgc.headerText = resourceManager('ProfileServ' + dgc.dataField);
   				dgc.setStyle("textAlign","center");
   				cf = new ClassFactory(OblikLogical);
				cf.properties = or;
				dgc.itemRenderer = cf;
   				aColumnsNew.push(dgc);
   			}
   			dgc = new DataGridColumn();                                  
   			dgc.dataField = "UserServiceName";     
			dgc.headerText = resourceManager('ProfileServ' + dgc.dataField);
      		dgc.width = 300;
			cf = new ClassFactory(OblikCharacter);
			cf.properties = or;
			dgc.itemRenderer = cf;
			aColumnsNew.push(dgc);
			dgc = new DataGridColumn();                                  
			dgc.width = 110;
			dgc.dataField = "ReadOnly";     
			dgc.headerText = resourceManager('ProfileServ' + dgc.dataField);
			dgc.setStyle("textAlign","center");
  			if (isAdmin == true)
  			{
				cf = new ClassFactory(OblikLogical);
				cf.properties = or;
  			}
			else
				cf = new ClassFactory(OblikLogicalBr);
			dgc.itemRenderer = cf;
   			aColumnsNew.push(dgc);
   			dgc = new DataGridColumn();                                  
   			dgc.dataField = "ServiceName";     
			dgc.headerText = resourceManager('ProfileServ' + dgc.dataField);
      		dgc.width = 200;
			aColumnsNew.push(dgc);
			dgc = new DataGridColumn();                                  
			dgc.dataField = "ServiceType";     
			dgc.headerText = resourceManager('ProfileServ' + dgc.dataField);
      		dgc.width = 200;
   			dgc.setStyle("textAlign","left");
   			aColumnsNew.push(dgc);
			dgc = new DataGridColumn();                                  
			dgc.dataField = "RunCount";     
			dgc.headerText = resourceManager('ProfileServ' + dgc.dataField);
      		dgc.width = 100;
   			dgc.setStyle("textAlign","right");
   			aColumnsNew.push(dgc);
   			dg = new DataGrid();
	    	dg.columns = aColumnsNew;           
	    	dg.editable = false;                           
  			dg.horizontalScrollPolicy = "auto"; 
  			dg.height = 300;
  			dg.rowHeight = 26;
			newform.addChild (dg);

			var saveButton:Button = new Button();
  			saveButton.label = resourceManager('ProfileSave');
  			saveButton.toolTip = resourceManager('ProfileSaveTip');
			saveButton.addEventListener(MouseEvent.CLICK, SaveUserProfile, false, 0, true);
			saveButton.enabled = ! iReadOnly;
			var cancelButton:Button = new Button();
  			cancelButton.label = resourceManager('ProfileCancel');
  			cancelButton.toolTip = resourceManager('ProfileCancelTip');
			cancelButton.addEventListener(MouseEvent.CLICK, CancelUserProfile, false, 0, true);
  			newHBox2 = new HBox();
  			newHBox2.addChild(saveButton);
  			newHBox2.addChild(cancelButton);
  			this.bSave = saveButton;
  			newform.addChild (newHBox2);
  				
  			newVBox.label = resourceManager('ProfileTitle');
  			if (iReadOnly == true) newVBox.label += ' (' + resourceManager('ProfileServReadOnly') + ')';
  			newVBox.addChild(newHBox);
  			newVBox.addChild(newVBox2);
  			newVBox.setStyle("paddingBottom", 10);
  			newVBox.setStyle("paddingLeft", 10);
  			newVBox.setStyle("paddingRight", 10);
  			rootBox = newVBox;
			return newVBox;
		}
		
		private function OnChangePass (e:Event):void
		{
			oldpass.enabled = e.target.selected && !isnew;
			confpass.enabled = e.target.selected;
			newpass.enabled = e.target.selected;
		}
		private function OnChangePass2 (e:KeyboardEvent):void
		{
			oldpass.enabled = e.target.selected && !isnew;
			confpass.enabled = e.target.selected;
			newpass.enabled = e.target.selected;
		}
        private function SaveUserProfile(event:Event):void
        {
        	if (isnewpass.selected == true && confpass.text != newpass.text)
        	{
        		Alert.show(resourceManager('ProfileBadPassword'));
        		return;
        	}
          	if (dp.length > 0)
          	{
	          	dbi.UserLogin = login.text;
    	      	dbi.UserName = username.text;
        	  	dbi.UserEMail = email.text;
          		dbi.UserCompany = ent.text;
          		dbi.UserPosition = cathg.text;
          		dbi.UserBanned = isbanned.selected;
				dbi.ConfPass = confpass.text;
				dbi.NewPass = newpass.text;
				dbi.OldPass = oldpass.text;
          		dbi.ChangePass = isnewpass.selected;
          	}
			SaveProfileoper.send(ContextId, isnew, dp, ds);
        }
        private function CancelUserProfile(event:Event):void
        {
			rootBox.dispatchEvent(new Event('CloseTab', true));
        }
        
        private function OnSaveProfile(event:ResultEvent):void
        {
        	if (event.result.OutMessage == "Error")
        		Alert.show(resourceManager('ProfileNotSaved'));
        	if (event.result.OutMessage == "BadUser")
        		Alert.show(resourceManager('ProfileBadUser'));
        	if (event.result.OutMessage == "BadPassword")
        		Alert.show(resourceManager('ProfileBadPassword'));
        	if (event.result.OutMessage == "OK")
        	{
        		isnew = false;
				rootBox.dispatchEvent(new Event('CloseTab', true));
/*
        		Alert.show(resourceManager('ProfileSaved'));
*/        		
        	}
        }
		
	}
}
