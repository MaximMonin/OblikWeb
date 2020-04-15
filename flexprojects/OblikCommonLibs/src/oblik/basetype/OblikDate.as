package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import flash.events.FocusEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	
	import mx.controls.DateField;
	import mx.controls.dataGridClasses.DataGridListData;
	import mx.controls.listClasses.BaseListData;
	import mx.events.CalendarLayoutChangeEvent;
	import mx.events.ValidationResultEvent;
	import mx.formatters.DateFormatter;
	import mx.resources.ResourceManager;
	import mx.validators.DateValidator;

	public class OblikDate extends DateField
	{
		public var df:DateFormatter;
		public var dv:DateValidator;
		public var InternalValue:Date;
		public var FormField:int;
		
		private var _listData:DataGridListData;
		private var _data:Object;

		public function OblikDate():void
		{
			super();
			this.width = 100;
			this.restrict = "0-9./-";
  			this.yearNavigationEnabled = true; 
  			this.firstDayOfWeek = int (RM('DateWeekFirstDay'));
  			this.formatString = RM('DateFormat');
  			this.dayNames = [RM('WD0'), RM('WD1'), RM('WD2'), RM('WD3'), RM('WD4'), RM('WD5'), RM('WD6')];
  			this.monthNames = [RM('DM1'), RM('DM2'), RM('DM3'), RM('DM4'), RM('DM5'),RM('DM6'), RM('DM7'), RM('DM8'), RM('DM9'), RM('DM10'), RM('DM11'),RM('DM12')];
  			this.showToday = true;
  			this.editable = true;
  			this.df = new DateFormatter ();
  			this.df.formatString = this.formatString;

  			this.dv = new DateValidator ();
  			this.dv.inputFormat = this.formatString;
			this.dv.formatError= RM('DateFormatError');
    		this.dv.invalidCharError=RM('DateInvalidCharError');
    		this.dv.validateAsString = true;
			this.dv.requiredFieldError=RM('DateRequiredFieldError'); 
    		this.dv.wrongDayError=RM('DateWrongDayError');
    		this.dv.wrongLengthError=RM('DateWrongLengthError'); 
    		this.dv.wrongMonthError=RM('DateWrongMonthError');
    		this.dv.wrongYearError=RM('DateWrongYearError');
    		this.dv.property = "text";
    		this.dv.source = this;
    		this.dv.required = false;
			this.addEventListener(FocusEvent.FOCUS_IN, FocusIn );
    		this.addEventListener(CalendarLayoutChangeEvent.CHANGE, ValidateText );		
    		this.addEventListener(KeyboardEvent.KEY_UP, ValidateText2);	
    		this.parseFunction = parseDate;
		}
		private function RM (messname:String):String
		{
			return ResourceManager.getInstance().getString('CommonLibs',messname);
		}
    	private function parseDate(valueString:String, inputFormat:String):Date 
    	{
          return DateField.stringToDate(valueString, inputFormat);
	    }
		
		public function get FormValue ():String
		{
			return this.text;
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
		public function set ReadOnly (value:Boolean):void
		{
			this.editable = ! value;
		}
		public function get ReadOnly ():Boolean
		{
			return ! this.editable;
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
			formatString = fs;
  			df.formatString = formatString;
  			dv.inputFormat = formatString;
		}
		
		private function validateDate1 ():void
		{
			var customDateEvent:ValidationResultEvent = this.dv.validate();
			if(customDateEvent.type==ValidationResultEvent.INVALID)
			{
				this.InternalValue = null;
/*
				Alert.show("Неверная дата. Введите дату в формате ДД/ММ/ГГГГ");
*/				
				return;
			}
			if (this.ReadOnly == false)
				SetValue(DateField.stringToDate(this.text, this.formatString));
			else
				SetValue(InternalValue);
			SaveData ();			
		}
		private function ValidateText (e:Event):void
		{
			validateDate1 ();
		}
		private function ValidateText2 (e:KeyboardEvent):void
		{
			if (e.charCode == 13)
			{
				validateDate1 ();
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
		private function SaveData ():void
		{
			if (data) data [ _listData.dataField ] = InternalValueStr;
/*			Alert.show ("DateCommitted"); */	
			this.dispatchEvent(new Event('ValueCommit', true));
		}
		private function FocusIn ( event:FocusEvent ):void
		{
			this.dispatchEvent(new Event('OnFocus', true));
		}
	}
}