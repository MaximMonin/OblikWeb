package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import mx.controls.DateField;
	import mx.controls.Label;
	import mx.controls.dataGridClasses.DataGridListData;
	import mx.controls.listClasses.BaseListData;
	import mx.formatters.DateFormatter;
	import mx.resources.ResourceManager;

	public class OblikDateBr extends Label
	{
		public var InternalValue:Date;
		public var df:DateFormatter;
		
		private var _listData:DataGridListData;
		private var _data:Object;

		public function OblikDateBr():void
		{
			super();
  			this.df = new DateFormatter ();
  			this.df.formatString = RM('DateFormat');
		}
		private function RM (messname:String):String
		{
			return ResourceManager.getInstance().getString('CommonLibs',messname);
		}
		
		public function get InternalValueStr ():String
		{
  			var df1:DateFormatter = new DateFormatter ();
  			df1.formatString = "DD/MM/YYYY";
			return df1.format(InternalValue);
		}
		public function set InternalValueStr (value:String):void
		{
			ParseDate (value);
		}
		public function set FormValueStr (value:String):void
		{
			ParseDate (value);
		}
		public function ParseDate (dt:String):void
		{
			if (!dt || dt == "")
			{
				SetValue (null);
				return;
			} 
       		if (dt.substr(4,1) == '-' ) /* Date format yyyy-mm-dd */
       		{
       			var dy:String = dt.substr(0,4);
       			var dm:String = dt.substr(5,2);
       			var dd:String = dt.substr(8,2);
        			
       			var dstr:String = dd + '/' + dm + '/' + dy;
        		SetValue(DateField.stringToDate(dstr, "DD/MM/YYYY"));
       		}	
       		else
       		{
       			if (dt.substr(2,1) == '/')
       				SetValue(DateField.stringToDate(dt, "DD/MM/YYYY"));
       			else
       			{
	   				var dt1:Date = new Date(Date.parse(dt));
   					SetValue (dt1);
       			}
       		}
		}
	
		public function SetValue (datevalue:Date):void
		{
			InternalValue = datevalue;
			if (InternalValue != null)
			{
				InternalValue.hours = 0 - InternalValue.timezoneOffset / 60.
			}	
			if (!InternalValue)
				this.text = "";
			else
			{
				var dt:String = df.format(datevalue);
				if (dt.indexOf("NaN",0) < 0) 
					this.text = dt;
				else
					this.text = "";
			}
		}
		public function SetFormat (fs:String):void
		{
  			df.formatString = fs;
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
		override public function get data():Object
        {
           	return _data;
        }
        override public function set data( value:Object ):void
        {
           	this._data = value;
       	
			if (!data)
				return;
			callLater( callLater, [_setData] );
							
        }
        private function _setData():void
        {
        	if (!data[ _listData.dataField ])
        		InternalValueStr = "";
        	else
        	{
        		ParseDate (data [ _listData.dataField ].toString());	
       		}
        }			
	}
}