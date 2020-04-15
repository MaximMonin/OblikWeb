package oblik.drivers
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import flash.events.Event;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.soap.Operation;
	import mx.rpc.soap.WebService;

	public class PrintFileTransfer extends FileTransfer
	{
		public var o:Object;
		public var Module:String;
		public var ViewOnly:Boolean;
		public var FileName:String;
		public var FileType:String;
		public var PrintParams:String;

  		private var _PrintDriver:Operation;
		protected var srv2:WebService;

		public function PrintFileTransfer()
		{
			super();
	        this.srv2 = new WebService();
			_PrintDriver = new Operation(null, "PrintDriver");
			_PrintDriver.addEventListener(ResultEvent.RESULT, OnPrintDriver, false, 0, true);
			_PrintDriver.addEventListener(FaultEvent.FAULT, Onfault, false, 0, true);
			this.srv2.operations = [this._PrintDriver];
			
			this.addEventListener("DownloadError", OnError);
			this.addEventListener("DownloadComplete", OnComplete);
		}
		public function PrintDriver (ContextId:String, servicepath:String):void
		{
			this.ContextId = ContextId;
			this.srv2.wsdl = servicepath;
			this.srv2.loadWSDL();
			this._PrintDriver.send (ContextId, this.Module, this.ViewOnly, this.FileName, this.FileType, this.PrintParams);
		}
        private function OnPrintDriver(e:ResultEvent):void
        {
            if (e.result.OutMessage != "")
            {
           		this.ErrorMessage = e.result.OutMessage;
				this.dispatchEvent(new Event('DownloadError', true));
            }	
            else
            {
            	this.LocalFileName = e.result.LocalFileName;
            	this.DownloadFile(this.ContextId, this.srv2.wsdl, e.result.HostFileName);
            }
        }
		private function OnError (e:Event):void
		{
			this.DeleteFile();
		}
		private function OnComplete (e:Event):void
		{
			this.DeleteFile();
		}
	}
}