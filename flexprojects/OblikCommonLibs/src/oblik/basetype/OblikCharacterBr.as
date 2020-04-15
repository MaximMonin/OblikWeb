package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import mx.controls.Label;
	import mx.controls.dataGridClasses.DataGridListData;
	import mx.controls.listClasses.BaseListData;

	public class OblikCharacterBr extends Label
	{
		public var FormField:int;
		private var _listData:DataGridListData;
		private var ChangeFlag:Boolean;

		public function OblikCharacterBr()
		{
			super();
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
        	if (!data[ _listData.dataField ] || (data[ _listData.dataField ].toString() == '[object Object]'))
        		InternalValueStr = "";
        	else
       			InternalValueStr = data [ _listData.dataField ];
        }			
	}
}