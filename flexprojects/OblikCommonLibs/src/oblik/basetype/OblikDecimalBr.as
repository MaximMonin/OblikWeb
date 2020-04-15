package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import mx.controls.Label;
	import mx.formatters.NumberBaseRoundType;
	import mx.formatters.NumberFormatter;

	import mx.controls.dataGridClasses.DataGridListData;
	import mx.controls.listClasses.BaseListData;
	import mx.resources.ResourceManager;

	public class OblikDecimalBr extends Label
	{
		public var nf:NumberFormatter;
		public var InternalValue:Number;
		public var FormField:int;
		private var ChangeFlag:Boolean;
		
		private var _listData:DataGridListData;
		
		public function OblikDecimalBr ()
		{
			super();
			this.setStyle("textAlign","right");
 			this.nf = new NumberFormatter ();
  			this.nf.useNegativeSign=true;
  			this.nf.useThousandsSeparator = true;
  			this.nf.precision = 2;
  			this.nf.rounding = NumberBaseRoundType.NEAREST;

    		this.SetValue (0);
  		}	
		private function RM (messname:String):String
		{
			return ResourceManager.getInstance().getString('CommonLibs',messname);
		}
		public function get FormValue ():String
		{
			return this.text;
		}
		public function get InternalValueStr ():String
		{
			return this.InternalValue.toString();
		}
		public function set InternalValueStr (value:String):void
		{
			var ft:String = value.replace(',','');
			InternalValue = Number(ft);
			if (InternalValue.toString() != "NaN")
			{
				SetValue(InternalValue);
			}
		}
		public function set FormValueStr (value:String):void
		{
			var ft:String = value.replace(',','');
			InternalValue = Number(ft);
			if (InternalValue.toString() != "NaN")
			{
				SetValue(InternalValue);
			}
		}
		public function set Format (value:String):void
		{
			SetFormat (value);
		}

		public function SetValue (intvalue:Number):void
		{
			InternalValue = intvalue;
			text = nf.format(intvalue);
		}
		public function SetFormat (fs:String):void
		{
			var fs1:String = fs.substr(0, 1);
			if (fs.indexOf(",") >= 0)
			{
	 			this.nf.useThousandsSeparator = true;
			}
			else
			{
	 			this.nf.useThousandsSeparator = false;
			}
			var fs2:String = fs;
			for(var j:uint; j < fs2.length; j++)
			{ 
				fs2 = fs2.replace(">", "9");
				fs2 = fs2.replace(",", "");
				fs2 = fs2.replace("-", "");
			}
    		if (fs2.indexOf(".") >= 0)
    		{
	  			this.nf.precision = fs2.length - fs2.indexOf(".") - 1;
	  			if (this.nf.precision < 0)
	  			{
	  				this.nf.precision = 0;
	  			}
    		}
    		else
    		{
    			this.nf.precision = 0;
    		}
    		SetValue (InternalValue);
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
        	{
        	    var ft:String = data [ _listData.dataField ];
        	    ft = ft.replace(',','');
       			InternalValueStr = ft;
       		}
        }			
	}
}