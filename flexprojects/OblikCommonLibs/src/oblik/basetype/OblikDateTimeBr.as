package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import mx.controls.DateField;
	import mx.controls.Label;
	import mx.controls.dataGridClasses.DataGridListData;
	import mx.controls.listClasses.BaseListData;
	import mx.formatters.DateFormatter;
	import mx.resources.ResourceManager;
	import mx.controls.Alert;

	public class OblikDateTimeBr extends Label
	{
		public var InternalValue:Date;
		public var df:DateFormatter;
		
		private var _listData:DataGridListData;
		private var _data:Object;

		public function OblikDateTimeBr():void
		{
			super();
  			this.df = new DateFormatter ();
  			this.df.formatString = RM('DateTimeFormat');
		}
		private function RM (messname:String):String
		{
			return ResourceManager.getInstance().getString('CommonLibs',messname);
		}
		
		public function get InternalValueStr ():String
		{
  			var df1:DateFormatter = new DateFormatter ();
  			df1.formatString = "DD/MM/YYYY JJ:NN:SS.QQQ";
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
   			if (dt.substr(4,1) == '-' && dt.substr(10,1) == "T") /* yyyy-mm-ddTHH:MM:SS.QQQ+03:00 -> yyyy/mm/dd hh:mm:ss GMT+0300 */
   			{
   				dt = dt.replace("-","/");
   				dt = dt.replace("-","/");
   				dt = dt.replace("T", " ");
   				dt = dt.replace("+", " GMT+");	
   				dt = dt.replace("-", " GMT-");	
   				dt = dt.substr(0,19) + dt.substr(23, 7) + dt.substr(dt.length - 2, 2);
   				var dt1:Date = new Date(Date.parse(dt));
   				SetValue (dt1);
   			}
   			else
   			{
   				dt1 = new Date(Date.parse(dt));
   				SetValue (dt1);
   			}
		}
		public function SetValue (datevalue:Date):void
		{
			InternalValue = datevalue;
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
       			var dt:String = data [ _listData.dataField ];
        		ParseDate (dt);
       		}	
        }			
	}
}
