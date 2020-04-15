package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import flash.events.FocusEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import mx.events.FlexEvent;
	
    import mx.controls.Alert;
 	import mx.controls.TextInput;
	import mx.events.ValidationResultEvent;
	import mx.formatters.NumberFormatter;
	import mx.validators.NumberValidator;
	import mx.resources.ResourceManager;

	import mx.controls.dataGridClasses.DataGridListData;
	import mx.controls.listClasses.BaseListData;

	public class OblikInteger extends TextInput
	{
		public var nf:NumberFormatter;
		public var nv:NumberValidator;
		public var InternalValue:uint;
		public var FormField:int;
		private var ChangeFlag:Boolean;
		
		private var _listData:DataGridListData;

		public function OblikInteger ()
		{
			super();
			this.restrict = "0-9";
			this.setStyle("textAlign","right");
 			this.nf = new NumberFormatter ();
  			this.nf.useNegativeSign=true;
  			this.nf.useThousandsSeparator = false;

  			this.nv = new NumberValidator ();
  			this.nv.allowNegative=false;
  			this.nv.domain="int"; 
			this.nv.requiredFieldError=RM('NumberRequiredFieldError'); 
    		this.nv.decimalPointCountError=RM('NumberDecimalPointError'); 
    		this.nv.exceedsMaxError=RM('NumberMaxError');
    		this.nv.integerError=RM('NumberIntegerError');
    		this.nv.invalidCharError=RM('NumberInvalidCharError'); 
    		this.nv.invalidFormatCharsError=RM('NumberInvalidFormatError'); 
    		this.nv.lowerThanMinError=RM('NumberMinError');
    		this.nv.negativeError=RM('NumberNegativeError');
    		this.nv.precisionError=RM('NumberPrecisionError'); 
    		this.nv.separationError=RM('NumberSeparationError');
    		this.nv.property = "text";
    		this.nv.source = this;
    		this.nv.required = true;
    		this.SetValue (0);
			this.addEventListener(FocusEvent.FOCUS_IN, FocusIn );
    		this.addEventListener(FlexEvent.VALUE_COMMIT, ValidateText);
    		this.addEventListener(KeyboardEvent.KEY_DOWN, ValidateText2);
    		this.addEventListener(Event.CHANGE, ValidateText3);
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
			InternalValue = int(ft);
			if (InternalValue.toString() != "NaN")
			{
				SetValue(InternalValue);
			}
		}
		public function set ReadOnly (value:Boolean):void
		{
			this.editable = ! value;
		}
		public function get ReadOnly ():Boolean
		{
			return ! this.editable;
		}
		public function set FormValueStr (value:String):void
		{
			var ft:String = value.replace(',','');
			InternalValue = int(ft);
			if (InternalValue.toString() != "NaN")
			{
				SetValue(InternalValue);
			}
		}
		public function set Format (value:String):void
		{
			SetFormat (value);
		}
		public function set Required (value:Boolean):void
		{
    		this.nv.required = value;
		}
		
		public function SetValue (intvalue:uint):void
		{
			InternalValue = uint(intvalue);
			text = nf.format(intvalue);
		}
		public function SetFormat (fs:String):void
		{
			this.maxChars = fs.length;
			var fs1:String = fs.substr(0, 1);
			if (fs1 == "-")
			{
				this.nv.allowNegative=true;
				this.restrict = "\-0-9";
			}
			else
			{
				this.nv.allowNegative=false;
				this.restrict = "0-9";
			}
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
			if (fs1 == "-")
			{
	  			this.nv.minValue= 0 - uint(fs2);
	  			this.nv.maxValue=uint(fs2); 
			}
			else
			{
				this.nv.minValue=0;
	  			this.nv.maxValue=uint(fs2);
			}
    		this.nv.lowerThanMinError=RM('NumberEnterValue') + " >= " + this.nv.minValue.toString();
    		this.nv.exceedsMaxError=RM('NumberEnterValue') + " <= " + this.nv.maxValue.toString();
    		SetValue (InternalValue);
		}
		private function ValidateText (e:Event):void
		{
			validateInteger ();
		}
		private  function ValidateText2 (e:KeyboardEvent):void
		{
			if (e.charCode == 13)
			{
				validateInteger ();
			}	
		}
		private function ValidateText3 (e:Event):void
		{
			ChangeFlag = true;
		}
		private function validateInteger():void
		{
			var customEvent:ValidationResultEvent = this.nv.validate();
			if(customEvent.type==ValidationResultEvent.INVALID)
			{
				this.InternalValue = 0;
/*
				Alert.show("Неверное число");
*/				
				return;
			}
			else
			{ 
				var ft:String = this.text.replace(',','');
				this.InternalValue = uint(ft);
				if (this.InternalValue.toString() != "NaN")
				{
					this.SetValue(this.InternalValue);
					if (this.ChangeFlag == true)
						SaveData ();
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
        		InternalValueStr = "";
        	else
        	{
        	    var ft:String = data [ _listData.dataField ];
        	    ft = ft.replace(',','');
       			InternalValueStr = ft;
       		}	
        }			
		private function SaveData ():void
		{
			this.ChangeFlag = false;
			if (data) data [ _listData.dataField ] = InternalValueStr;
			this.dispatchEvent(new Event('ValueCommit', true));
		}
		private function FocusIn ( event:FocusEvent ):void
		{
			this.dispatchEvent(new Event('OnFocus', true));
		}
	}
}