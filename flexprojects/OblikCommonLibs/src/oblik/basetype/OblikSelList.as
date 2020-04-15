package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import flash.events.FocusEvent;
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.controls.ComboBox;
	import mx.controls.dataGridClasses.DataGridListData;
	import mx.controls.listClasses.BaseListData;
	import mx.events.DropdownEvent;
	import mx.events.ListEvent;

	public class OblikSelList extends ComboBox
	{
		public var FormField:int;
		private var _listData:DataGridListData;
		private var oldvalue:String;

		public function OblikSelList()
		{
			super();
			this.setStyle("fontWeight", "normal");
  			this.rowCount = 20;
			this.addEventListener(FocusEvent.FOCUS_IN, FocusIn );
  			this.addEventListener(ListEvent.CHANGE, ChangeValue );
  			this.addEventListener(DropdownEvent.OPEN, BeforeChangeValue );
		}
		public function get FormValue ():String
		{
			return this.text;
		}
		public function get InternalValue ():String
		{
			return this.text;
		}
		public function get InternalValueStr ():String
		{
			return this.text;
		}
		public function set InternalValueStr (value:String):void
		{
			SetValue (value);
		}
		public function set FormValueStr (value:String):void
		{
			SetValue (value);
		}
		public function set ReadOnly (value:Boolean):void
		{
			this.mouseEnabled = !value;
			this.mouseFocusEnabled = !value;
		}
		public function get ReadOnly ():Boolean
		{
			return ! this.mouseEnabled;
		}
		public function set Items (value:String):void
		{
			SetItems (value);
		}
		public function SetValue (inpvalue:String):void
		{
			text = inpvalue;
		}
		public function SetItems (ItemList:String):void
		{
			var item1:Object;
			var sellist:ArrayCollection = new ArrayCollection();
			do
			{
				item1 = new Object();
				if (ItemList.indexOf(",") >= 0)
				{
					item1["label"] = ItemList.substring(0,ItemList.indexOf(","));
					ItemList = ItemList.substring(ItemList.indexOf(",") + 1);
				}
				else
				{
					item1["label"] = ItemList;
					ItemList = "";
				}	 
				sellist.addItem (item1);
			} while (ItemList != "");
			this.dataProvider = sellist;	
    		this.selectedItem = null;
			SetValue ("");		
		}
		
		private function ChangeValue (e:Event):void
		{
			if (this.ReadOnly == true)
			{
				SetValue (oldvalue);
			}
			else
			{
				SetValue(this.text);
				SaveData ();
			}
		}
		private function BeforeChangeValue (e:Event):void
		{
			oldvalue = this.text;
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
        		InternalValueStr = "";
        	else
       			InternalValueStr = data [ _listData.dataField ];
        }			
		private function SaveData ():void
		{
			if (this.ReadOnly == true) return;
			if (data) data [ _listData.dataField ] = InternalValueStr;
			this.dispatchEvent(new Event('ValueCommit', true));
			this.dispatchEvent(new Event('ValueSelect', true));
		}
		private function FocusIn ( event:FocusEvent ):void
		{
			this.dispatchEvent(new Event('OnFocus', true));
		}
	}
}