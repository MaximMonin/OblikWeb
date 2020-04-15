package oblik.drivers
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import flash.events.Event;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.soap.Operation;
	import mx.rpc.soap.WebService;

	public class DocFileTransfer extends FileTransfer
	{
		public var o:Object;
		public var RidDoc:int;

		private var _DocFileAdd:Operation;
  		private var _DocFileView:Operation;
		protected var srv2:WebService;

		public function DocFileTransfer()
		{
			super();
			
	        this.srv2 = new WebService();
			_DocFileAdd = new Operation(null, "DocFileAdd");
			_DocFileAdd.addEventListener(ResultEvent.RESULT, OnDocFileAdd, false, 0, true);
			_DocFileAdd.addEventListener(FaultEvent.FAULT, Onfault, false, 0, true);
			_DocFileView = new Operation(null, "DocFileView");
			_DocFileView.addEventListener(ResultEvent.RESULT, OnDocFileView, false, 0, true);
			_DocFileView.addEventListener(FaultEvent.FAULT, Onfault, false, 0, true);
			this.srv2.operations = [this._DocFileAdd, this._DocFileView];
			this.addEventListener("DownloadError", OnError);
			this.addEventListener("DownloadComplete", OnComplete);
			
		}
		public function DocFileAdd ():void
		{
			this.srv2.wsdl = this.srv.wsdl;
			this.srv2.loadWSDL();
			this._DocFileAdd.send (this.ContextId, this.RidDoc, this.HostFileName, this.LocalFileName);
		}
		public function DocFileView (ContextId:String, servicepath:String, RidFileDoc:int):void
		{
			this.ContextId = ContextId;
			this.srv2.wsdl = servicepath;
			this.srv2.loadWSDL();
			this._DocFileView.send (ContextId, RidFileDoc);
		}
		
        private function OnDocFileAdd(e:ResultEvent):void
        {
            if (e.result.OutMessage != "")
            {
           		this.ErrorMessage = e.result.OutMessage;
				this.dispatchEvent(new Event('UploadError', true));
            }	
            else
				this.dispatchEvent(new Event('DocUploadComplete', true));
			
        }
        private function OnDocFileView(e:ResultEvent):void
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