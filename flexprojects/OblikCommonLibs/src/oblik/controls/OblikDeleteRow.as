package oblik.controls
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	import mx.resources.ResourceManager;
	import mx.controls.LinkButton;

	public class OblikDeleteRow extends LinkButton
	{
		[Embed(source="remove.png")]
		private var remove_icon:Class;
		
		public function OblikDeleteRow()
		{
			super();
           	this.toolTip = RM('DeleteRow');
            this.setStyle ("icon", remove_icon);
            this.width = 15;
            this.height = 15;
            this.addEventListener(MouseEvent.CLICK, HandleClick );
		}
		private function RM (messname:String):String
		{
			return ResourceManager.getInstance().getString('CommonLibs',messname);
		}
	
		private function HandleClick (event:MouseEvent):void
		{
			this.dispatchEvent(new Event('deleteRow', true))
		}
		
	}
}