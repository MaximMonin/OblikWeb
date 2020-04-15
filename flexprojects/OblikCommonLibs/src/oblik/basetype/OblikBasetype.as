package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import com.hillelcoren.components.AutoComplete;
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.xml.XMLDocument;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.controls.dataGridClasses.DataGridListData;
	import mx.controls.listClasses.BaseListData;
	import mx.resources.ResourceManager;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.soap.Operation;
	import mx.rpc.soap.WebService;
	import mx.rpc.xml.SimpleXMLDecoder;
	
	import oblik.basetype.DocDataGridColumn;

	public class OblikBasetype extends AutoComplete
	{
		[Embed(source="down.png")]
		private var browse_icon:Class;

		public var InternalValue:String;
		public var FormValue:String;
		public var FormField:int;
		public var ContextParam:String;
		public var AppendParam:String;
		public var delayTimer:Timer;
		public var MinSearchLength:int;
		public var sellist:ArrayCollection;
		public var ContextId:String;
		public var basetype:String;
		public var srv:WebService;
		public var TypeOper:Operation;
		public var BrowseOper:Operation;
		public var GotAllRecords:Boolean;
		public var AllRecordsList:ArrayCollection;
		public var EditMode:Boolean;
		public var ReadOnly:Boolean;
		private var EnterPressed:Boolean;
		private var RequestProsessing:Boolean;
		private var SearchChanged:Boolean;
		private var ChangeFlag:Boolean;
		private var b:Button;

		public var AskContext:Boolean;
		private var _GotContext:Boolean;
		private var ContextAction:String;
		
		private var _listData:DataGridListData;
		
		override public function OblikBasetype()
		{
			super();
			
			b = new Button ();
            b.setStyle ("icon", browse_icon);
            b.setStyle( "styleName", "actionsMenuButton" );
            b.addEventListener(MouseEvent.CLICK, BrowseData );
            
			this.enableClearIcon = false;
			this.allowEditingNewValues = false;
			this.allowNewValues = false;
			this.EditMode = false;
			this.autoSelectEnabled = false;
			this.allowMultipleSelection = false;
			this.backspaceAction = "remove";
			this.dropDownRowCount = 10;
			this.matchType="anyPart";
			this.filterFunction = Filter;
			
			this.labelField = "FormValue";
			this.setStyle("selectedItemStyleName","underline");
			
			this.MinSearchLength = 1;
			this.GotAllRecords = false;
			this.sellist = new ArrayCollection();
			this.dataProvider = this.sellist;
			this.addEventListener("searchChange", OnSearchChange);
			this.addEventListener("change", OnValueChange);
			this.addEventListener( FocusEvent.FOCUS_IN, FocusIn );
			this.addEventListener( FocusEvent.FOCUS_OUT, FocusOut );
			
	        this.srv = new WebService();
			this.TypeOper = new Operation(null, "BasetypeSearch");
			this.TypeOper.addEventListener(ResultEvent.RESULT, OnListData);
			this.TypeOper.addEventListener(FaultEvent.FAULT, Onfault);
			this.TypeOper.resultFormat = "e4x";
			this.BrowseOper = new Operation(null, "BasetypeSelect");
			this.BrowseOper.addEventListener(ResultEvent.RESULT, OnBrowseData);
			this.BrowseOper.addEventListener(FaultEvent.FAULT, Onfault);
			this.BrowseOper.resultFormat = "e4x";
			this.srv.operations = [this.TypeOper, this.BrowseOper];
			this.EnterPressed = false;
			this.RequestProsessing = false;
			this.SearchChanged = false;
			
			this.FormValue = "";
			this.InternalValue = "";
			
			this.AskContext = false;
			this._GotContext = true;
			this.ContextAction = "";
		}
		public function get InternalValueStr ():String
		{
			return this.InternalValue;
		}
		public function set InternalValueStr (value:String):void
		{
			this.InternalValue = value;
		}
		public function set FormValueStr (value:String):void
		{
			if (!value) value = "";
			this.FormValue = value;
			this.selectedItems.removeAll();
			if (this.inlineButton == b && value != "")
			{
				var o:Object = new Object();
				o.FormValue = this.FormValue;
				o.IntValue = this.InternalValue; 
				this.textInput.text = "";
				this.selectedItems.addItem(o);
			}
			else
			{
				this.textInput.text = value;
			}
		}
		public function set webservice (value:String):void
		{
			SetWebService (value);
		}
		public function set canedit (value:Boolean):void
		{
			CanEdit (value);
		}
	
		public function CanEdit (eflag:Boolean):void
		{
			this.allowEditingNewValues = eflag;
			this.EditMode = eflag;
		}
		private function Filter (obj:Object, searchStr:String):Boolean
		{
			return true;
		}  
		private function FocusIn ( event:FocusEvent ):void
		{
			this.dispatchEvent(new Event('OnFocus', true));
			callLater( callLater, [_FocusIn] );
		}				
		private function _FocusIn ():void
		{
			if (this.ReadOnly == false)
			{
            	this.inlineButton = b;
	            this.inlineButton.enabled = true;
	  		}
	  		else
	  		{
	  			this.textInput.textInput.editable = false;
	  		}
            if (this.AskContext == true)
            {
	            _GotContext = false;
	            this.ContextAction = "";
	            this.GotAllRecords = false;
            }
			if (this.EditMode == false && this.ReadOnly == false)
			{
				var o:Object = new Object();
				o.FormValue = this.FormValue;
				o.IntValue = this.InternalValue; 
				this.textInput.text = "";
				this.selectedItems.addItem(o);
			}	
			else
				this.textInput.setTextSelected(true);
			this.textInput.addEventListener(KeyboardEvent.KEY_DOWN, KeyPressed);
			this.ChangeFlag = false;
		}
		private function FocusOut ( event:FocusEvent ):void
		{
			this.inlineButton = null;
  			this.textInput.textInput.editable = true;
			this.textInput.removeEventListener(KeyboardEvent.KEY_DOWN, KeyPressed);
			this.textInput.setTextSelected(false);
			if (this.selectedItem == null && this.textInput.text == "" && this.ReadOnly == false)
			{
				if (this.InternalValue != "") this.ChangeFlag = true;
				this.FormValue = "";
				this.InternalValue = "";
			}
			if (this.EditMode == true && this.ReadOnly == false)
			{
				if (this.selectedItem == null || this.selectedItem is String)
				{
					if (this.InternalValue != this.textInput.text) this.ChangeFlag = true;
					this.FormValue = this.textInput.text;
					this.InternalValue = this.textInput.text;
				}
				else
				{
					if (this.InternalValue != this.selectedItem.IntValue) this.ChangeFlag = true;
					this.FormValue = this.selectedItem.FormValue;
					this.InternalValue = this.selectedItem.IntValue;
				}
			}
			this.selectedItems.removeAll();
			this.textInput.text = this.FormValue;
			if (this.ReadOnly == false)
				SaveData ("Focus");
		}
		private function OnValueChange (event:Event):void
		{
			if (this.ReadOnly == true) return;
			if (this.selectedItem != null)
			{
				if (this.InternalValue != this.selectedItem.IntValue) this.ChangeFlag = true;
				this.FormValue = this.selectedItem.FormValue;
				this.InternalValue = this.selectedItem.IntValue;
			}
			else
			{
				if (this.InternalValue != "") this.ChangeFlag = true;
				this.FormValue = "";
				this.InternalValue = "";
			}
			
			if (this.EditMode == true)
			{
				this.selectedItems.removeAll();
				this.textInput.text = this.FormValue;
			}
			SaveData ("Select");
		}
		public function SetValue (formvalue:String, intvalue:String):void
		{
			InternalValue = intvalue;
			FormValue = formvalue;
			callLater( callLater, [_setValue] );
		}
        private function _setValue():void
        {
			this.textInput.text = FormValue;
        }			
		public function SetWebService (servicepath:String):void
		{
			this.srv.wsdl = servicepath;
			this.srv.loadWSDL();
		}
        public function set GotContext( value:Boolean ):void
        {
          	_GotContext = value;   
          	if (this.ContextAction == "Search")
          		SearchChange ();         	
          	if (this.ContextAction == "Browse")
          		BrowseData2 ();         	
        }
		private function OnSearchChange (e:Event):void
		{
			if (_GotContext == false && this.searchText.length >= this.MinSearchLength)
			{
				this.dispatchEvent(new Event('GetContext', true));
				this.ContextAction = "Search";
			}
			else
				SearchChange ();
		}
		private function SearchChange ():void
		{	
			/* Если пользователь быстро печатает и промежуток между нажатиями менее пол секунды, то не посылаем запросы к БД */
			if (this.ReadOnly == true) return;
			if (this.delayTimer != null && this.delayTimer.running) 
			{
				this.delayTimer.stop();
			}
			if (this.searchText.length >= this.MinSearchLength) 
			{
				this.sellist.removeAll();
				this.delayTimer = new Timer( 500, 1 );
				this.delayTimer.addEventListener(TimerEvent.TIMER, SearchData);
				this.delayTimer.start();
			}
		}
		private function SearchData( e:Event ):void
		{
			if (this.RequestProsessing == false)
			{
   	    		this.TypeOper.send (this.ContextId, this.basetype, this.AppendParam, this.ContextParam, this.searchText);
   	   	    	this.RequestProsessing = true;
   			}
   			else
   				this.SearchChanged = true;	
		}
		private function BrowseData( e:Event ):void
		{
			if (_GotContext == false)
			{
				this.dispatchEvent(new Event('GetContext', true));
				this.ContextAction = "Browse";
			}
			else
				BrowseData2 ();
		}	
		private function BrowseData2 ():void
		{
			if (this.ReadOnly == true) return;
			if (this.GotAllRecords == true)
			{
				var a2:ArrayCollection = new ArrayCollection();
				for (var i:uint = 0; i < this.AllRecordsList.length; i++) 
				{
    				a2.addItem(this.AllRecordsList.getItemAt(i));
				}
/*				
				this.sellist.removeAll();
*/				
				this.sellist = a2;
				
	    		this.dataProvider = this.sellist;
    			this.search();
    			if (this.isDropDownVisible() == false && this.sellist.length > 0)
					this.showDropDown();
			}
			else
			{
				if (this.RequestProsessing == false)
				{
    	   	    	this.BrowseOper.send (this.ContextId, this.basetype, this.AppendParam, this.ContextParam, this.searchText);
    	   	    	this.RequestProsessing = true;
    			}	
   			} 
		}
        private function Onfault(event:FaultEvent):void
        {
            Alert.show(event.fault.faultString, RM('ConnectionError'));
            EnterPressed = false;
        }
		private function RM (messname:String):String
		{
			return ResourceManager.getInstance().getString('CommonLibs',messname);
		}
        private function OnListData(event:ResultEvent):void
        {
        	this.RequestProsessing = false;
        	if (this.SearchChanged == true)
        	{
   	    		this.TypeOper.send (this.ContextId, this.basetype, this.AppendParam, this.ContextParam, this.searchText);
	        	this.SearchChanged = false;
        		return;
        	}
        	this.SearchChanged = false;

            var xmlStr:String = event.result.toString();
            var xmlDoc:XMLDocument = new XMLDocument(xmlStr);
            var decoder:SimpleXMLDecoder = new SimpleXMLDecoder(true);
            var resultObj:Object = decoder.decodeXML(xmlDoc);
            var oneObj:Object;
            
/*            Alert.show(ObjectUtil.toString(resultObj)); */   
    		if (resultObj.BasetypeSearchResponse.SearchData.DataSet.Data != null) // Пришло > 0 записей
    		{
    			if (resultObj.BasetypeSearchResponse.SearchData.DataSet.Data.Item.source != null) // Пришло > 1 записи
    			{
	    			this.sellist = resultObj.BasetypeSearchResponse.SearchData.DataSet.Data.Item;
	    		}	
	    		else  // Пришла 1 запись - формат ответа нестандартный 
	    		{
	    			this.sellist = new ArrayCollection();
	    			oneObj = resultObj.BasetypeSearchResponse.SearchData.DataSet.Data.Item;
	    			this.sellist.addItem(oneObj);
		    		this.dataProvider = this.sellist;
	    			if (this.EnterPressed)
	    			{
	    				this.selectedItem = oneObj;
						this.FormValue = oneObj.FormValue;
						this.InternalValue = oneObj.IntValue;
						if (this.EditMode == true)
						{
							this.selectedItems.removeAll();
							this.textInput.text = this.FormValue;
						}
						SaveData ("Select");
	    			}
	    		}
    		}
    		else
    		{
    			this.sellist.removeAll();
    		}
    		EnterPressed = false;
    		this.dataProvider = this.sellist;
    		this.search();
/*    		
    		if (this.dropDown != null)
    			this.dropDown.percentWidth = 100;
*/    			
        }
        private function OnBrowseData(event:ResultEvent):void
        {
        	this.RequestProsessing = false;

            var xmlStr:String = event.result.toString();
            var xmlDoc:XMLDocument = new XMLDocument(xmlStr);
            var decoder:SimpleXMLDecoder = new SimpleXMLDecoder(true);
            var resultObj:Object = decoder.decodeXML(xmlDoc);
            var oneObj:Object;
            
/*            Alert.show(ObjectUtil.toString(resultObj)); */
   			this.GotAllRecords = resultObj.BasetypeSelectResponse.AllRecords;
    		if (resultObj.BasetypeSelectResponse.SearchData.DataSet.Data != null) // Пришло > 0 записей
    		{
    			if (resultObj.BasetypeSelectResponse.SearchData.DataSet.Data.Item.source != null) // Пришло > 1 записи
    			{
	    			this.sellist = resultObj.BasetypeSelectResponse.SearchData.DataSet.Data.Item;
	    		}	
	    		else  // Пришла 1 запись - формат ответа нестандартный 
	    		{
	    			this.sellist = new ArrayCollection();
	    			oneObj = resultObj.BasetypeSelectResponse.SearchData.DataSet.Data.Item;
	    			this.sellist.addItem(oneObj);
	    		}
    		}
    		else
    		{
    			this.sellist.removeAll();
    		}
    		if (this.GotAllRecords == true) 
    		{
    			var a2:ArrayCollection = new ArrayCollection();
				for (var i:uint = 0; i < this.sellist.length; i++) 
				{
    				a2.addItem(this.sellist.getItemAt(i));
				}
				this.AllRecordsList = a2;
    		}
    		EnterPressed = false;
    		this.dataProvider = this.sellist;
    		this.search();
   			if (this.isDropDownVisible() == false && this.sellist.length > 0)
				this.showDropDown();
        }
        
        private function KeyPressed(event:KeyboardEvent):void
        {
			if (this.ReadOnly == true) return;
        	if (event.charCode == 13 && this.sellist.length == 0 && this.EditMode == false)
            {
	        	if (this.searchText.length >= this.MinSearchLength)
    	    	{
    	    		this.EnterPressed = true;
        	    	this.TypeOper.send (this.ContextId, this.basetype, this.AppendParam, this.ContextParam, this.searchText); 
        		}
            }    
        }

		override public function get listData():BaseListData
        {
           	return _listData;
        }
        override public function set listData( value:BaseListData ):void
        {
        	super.listData = value;
          	_listData = DataGridListData( value );            	
        }
        override public function set data( value:Object ):void
        {
           	super.data = value;
			if (!data)
				return;
			callLater( callLater, [_setData] );				
        }
        private function _setData():void
        {
        	if (!data[ _listData.dataField ])
        		FormValueStr = "";
        	else
       			FormValueStr = data [ _listData.dataField ];
       		if (listData.owner is DataGrid)
       		{
       			var d:DataGridColumn = (listData.owner as DataGrid).columns[_listData.columnIndex];
       			if (d is DocDataGridColumn && (d as DocDataGridColumn).InternalDataField)
       			{
		       		InternalValueStr = data [ (d as DocDataGridColumn).InternalDataField ];
       			}
       		}
        }			
		private function SaveData (Mode:String):void
		{
			if (data)
			{
				data [ _listData.dataField ] = FormValue;
	       		if (listData.owner is DataGrid)
    	   		{
       				var d:DataGridColumn = (listData.owner as DataGrid).columns[_listData.columnIndex];
       				if (d is DocDataGridColumn && (d as DocDataGridColumn).InternalDataField)
       				{
		       			data [ (d as DocDataGridColumn).InternalDataField ] = InternalValue;
       				}
       			}
			}
			if (Mode == "Focus" && this.ChangeFlag == true)
				this.dispatchEvent(new Event('ValueCommit', true));
			if (Mode == "Select")
				this.dispatchEvent(new Event('ValueSelect', true));
		}
	}
}