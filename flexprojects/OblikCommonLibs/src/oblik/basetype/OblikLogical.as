package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import flash.events.FocusEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	
	import mx.controls.CheckBox;
	import mx.controls.dataGridClasses.DataGridListData;
	import mx.controls.listClasses.BaseListData;

	public class OblikLogical extends CheckBox
	{
		public var InternalValue:Boolean;
		public var FormField:int;
		private var _listData:DataGridListData;

		public function OblikLogical()
		{
			super();
    		this.addEventListener(FocusEvent.FOCUS_IN, FocusIn );
			this.addEventListener(Event.CHANGE, ChangeValue )	
    		this.addEventListener(KeyboardEvent.KEY_UP, ChangeValue2);
		}
		public function get FormValue ():String
		{
			if (this.InternalValue == true) return "yes";
			else return "no";
		}
		public function get InternalValueStr ():String
		{
			return this.FormValue;
		}
		public function set InternalValueStr (value:String):void
		{
			if (value == "true" || value == "Да" || value == "yes")
				this.InternalValue = true;
			else
				this.InternalValue = false;
			SetValue (this.InternalValue);	
		}
		public function set FormValueStr (value:String):void
		{
			if (value == "true" || value == "Да" || value == "yes")
				this.InternalValue = true;
			else
				this.InternalValue = false;
			SetValue (this.InternalValue);	
		}
		public function set ReadOnly (value:Boolean):void
		{
			this.mouseEnabled = ! value;
		}
		public function get ReadOnly ():Boolean
		{
			return ! this.mouseEnabled;
		}
		public function SetValue (inpvalue:Boolean):void
		{
			InternalValue = inpvalue;
			selected = inpvalue;
		}
		private function ChangeValue (e:Event):void
		{
			SetValue(this.selected);
			SaveData ();
		}
		private function ChangeValue2 (e:KeyboardEvent):void
		{
			if (e.charCode == 13 || e.charCode == 20) // Enter + Space 
			{
				SetValue( ! this.InternalValue);
				SaveData ();
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
        		InternalValueStr = "";
        	else
       			InternalValueStr = data [ _listData.dataField ];
        }			
		private function SaveData ():void
		{
			if (data)
			{
				if (data [ _listData.dataField ] is Boolean)
					data [ _listData.dataField ] = InternalValue;
				else
					data [ _listData.dataField ] = InternalValueStr;
			}
			this.dispatchEvent(new Event('ValueCommit', true));
		}
		private function FocusIn ( event:FocusEvent ):void
		{
			this.dispatchEvent(new Event('OnFocus', true));
		}
	}
}