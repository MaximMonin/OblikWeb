package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import mx.controls.Button;
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class OblikButton extends Button
	{
		public var FormField:int;

		public function OblikButton()
		{
			super();
    		this.addEventListener(MouseEvent.CLICK, ButtonClick );	
		}
		public function set ReadOnly (value:Boolean):void
		{
			this.mouseEnabled = ! value;
		}
		public function get ReadOnly ():Boolean
		{
			return ! this.mouseEnabled;
		}
		private function ButtonClick( e:Event ):void
		{
			if (this.ReadOnly == false)
				this.dispatchEvent(new Event('ButtonClick', true));
		}
	}
}