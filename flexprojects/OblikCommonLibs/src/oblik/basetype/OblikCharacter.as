package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import mx.controls.TextInput;
	import mx.controls.dataGridClasses.DataGridListData;
	import mx.controls.listClasses.BaseListData;
	import flash.events.FocusEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import mx.events.FlexEvent;

	public class OblikCharacter extends TextInput
	{
		public var FormField:int;
		private var _listData:DataGridListData;
		private var ChangeFlag:Boolean;

		public function OblikCharacter()
		{
			super();
			this.addEventListener(FocusEvent.FOCUS_IN, FocusIn );
    		this.addEventListener(FlexEvent.VALUE_COMMIT, SaveData);
    		this.addEventListener(KeyboardEvent.KEY_DOWN, SaveData2);
    		this.addEventListener(Event.CHANGE, SaveData3);
		}
		public function get InternalValue ():String
		{
			return this.text;
		}
		public function get FormValue ():String
		{
			return this.text;
		}
		public function get InternalValueStr ():String
		{
			return this.InternalValue;
		}
		public function set InternalValueStr (value:String):void
		{
			this.text = value;
		}
		public function set FormValueStr (value:String):void
		{
			this.text = value;
		}
		public function set ReadOnly (value:Boolean):void
		{
			this.editable = ! value;
		}
		public function get ReadOnly ():Boolean
		{
			return ! this.editable;
		}
		private  function SaveData2 (e:KeyboardEvent):void
		{
			if (e.charCode == 13)
			{
				SaveData (e);
			}	
		}
		private function SaveData3 (e:Event):void
		{
			ChangeFlag = true;
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
		private function SaveData (e:Event):void
		{
			if (data) data [ _listData.dataField ] = InternalValueStr;
			if (this.ChangeFlag == false) return;
			this.ChangeFlag = false;
			this.dispatchEvent(new Event('ValueCommit', true));
		}
		private function FocusIn ( event:FocusEvent ):void
		{
			this.dispatchEvent(new Event('OnFocus', true));
		}
	}
}