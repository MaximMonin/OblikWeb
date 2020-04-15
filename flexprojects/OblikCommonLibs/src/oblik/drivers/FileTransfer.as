package oblik.drivers
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import mx.resources.ResourceManager;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.soap.Operation;
	import mx.rpc.soap.WebService;

	public class FileTransfer extends FileReference
	{
		protected var ContextId:String;
		protected var srv:WebService;
		protected var FileDOper1:Operation;
		protected var FileDOper2:Operation;
		protected var FileUOper1:Operation;
		protected var FileUOper2:Operation;
		protected var FileDelOper:Operation;

		public var trData:ByteArray;
		public var TotBytes:int;
		public var TrBytes:int;
		public var ChunkSize:int;
		public var HostFileName:String;
		public var LocalFileName:String;
		public var ErrorMessage:String;
		public var WorkDone:Boolean;
		public var WorkCanceled:Boolean;
		
		public var Mode:String;
		
		public function FileTransfer()
		{
			super();

	        this.srv = new WebService();
			this.FileDOper1 = new Operation(null, "FileDBegin");
			this.FileDOper1.addEventListener(ResultEvent.RESULT, OnFileDInfo);
			this.FileDOper1.addEventListener(FaultEvent.FAULT, Onfault);
			this.FileDOper2 = new Operation(null, "FileDChunk");
			this.FileDOper2.addEventListener(ResultEvent.RESULT, OnFileDData);
			this.FileDOper2.addEventListener(FaultEvent.FAULT, Onfault);
			this.FileUOper1 = new Operation(null, "FileUBegin");
			this.FileUOper1.addEventListener(ResultEvent.RESULT, OnFileUInfo);
			this.FileUOper1.addEventListener(FaultEvent.FAULT, Onfault);
			this.FileUOper2 = new Operation(null, "FileUChunk");
			this.FileUOper2.addEventListener(ResultEvent.RESULT, OnFileUData);
			this.FileUOper2.addEventListener(FaultEvent.FAULT, Onfault);
			this.FileDelOper = new Operation(null, "FileDelete");
			this.FileDelOper.addEventListener(ResultEvent.RESULT, OnFileDelete);
			this.FileDelOper.addEventListener(FaultEvent.FAULT, Onfault);
			this.srv.operations = [this.FileDOper1, this.FileDOper2, this.FileUOper1, this.FileUOper2, this.FileDelOper];
			
			this.trData = new ByteArray ();
			this.ChunkSize = 102400; /* 100кб */
			this.ErrorMessage = "";

            this.addEventListener(Event.SELECT, selectHandler);
            this.addEventListener(Event.COMPLETE, completeHandler);
            this.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		private function RM (messname:String):String
		{
			return ResourceManager.getInstance().getString('CommonLibs',messname);
		}

		public function DownloadFile (ContextId:String, servicepath:String, HostFileName:String):void
		{
			this.Mode = "Download";
			this.WorkDone = false;
			this.WorkCanceled = false;
			this.ContextId = ContextId;
			this.SetWebService(servicepath);
			this.FileDOper1.send(this.ContextId, HostFileName);
			this.HostFileName = HostFileName;
			this.dispatchEvent(new Event('DownloadBegin', true));
		}
		public function SaveFile (DefaultFileName:String):void
		{
			if (DefaultFileName == "")
			{
				
			}
			this.LocalFileName = DefaultFileName;
			this.save (this.trData, this.LocalFileName);
		}
		public function UploadFile (ContextId:String, servicepath:String, Filter:Array):void
		{
			this.Mode = "Upload";
			this.WorkDone = false;
			this.WorkCanceled = false;
			this.HostFileName = "";
			this.ContextId = ContextId;
			this.SetWebService(servicepath);
			if (Filter == null)
			{
				var AllTypes:FileFilter = new FileFilter(RM('FileTransferAllFiles') + " (*.*)", "*.*");
				Filter = new Array(AllTypes);
			}
			this.browse (Filter);
		}
		public function CancelUpload ():void
		{
			if (this.WorkDone == false)
			{
				this.WorkCanceled = true;
			}
		}
		public function DeleteFile ():void
		{
			this.FileDelOper.send (this.ContextId, this.HostFileName);
		}
		
		private function SetWebService (servicepath:String):void
		{
			this.srv.wsdl = servicepath;
			this.srv.loadWSDL();
		}
        private function OnFileDInfo(e:ResultEvent):void
        {
           	this.TotBytes = e.result.HostFileSize;
           	if (e.result.OutMessage != "")
           	{
           		this.ErrorMessage = e.result.OutMessage;
				this.dispatchEvent(new Event('DownloadError', true));
           	}	
            else
            {
            	this.FileDOper2.send (this.ContextId, this.HostFileName, 1, this.ChunkSize);
				this.dispatchEvent(new Event('DownloadProgress', true));
            }
        }
        private function OnFileDData(e:ResultEvent):void
        {
            this.TotBytes = e.result.HostFileSize;
            this.TrBytes = e.result.BytesTo;
            if (e.result.OutMessage != "")
            {
           		this.ErrorMessage = e.result.OutMessage;
				this.dispatchEvent(new Event('DownloadError', true));
            }	
            else
            {
            	if (this.TrBytes >= this.TotBytes)
            	{
	            	trData.writeBytes(e.result.FileBinary);
					this.dispatchEvent(new Event('DownloadComplete', true));
	            }
            	else
            	{
            		FileDOper2.send (this.ContextId, this.HostFileName, this.TrBytes + 1, this.TrBytes + this.ChunkSize);	
	            	trData.writeBytes(e.result.FileBinary);
					this.dispatchEvent(new Event('DownloadProgress', true));
            	}
           	}
        }
        protected function Onfault(event:FaultEvent):void
        {
          	this.ErrorMessage = event.fault.faultString;
          	if (this.Mode == "Download")
				this.dispatchEvent(new Event('DownloadError', true));
			else
				this.dispatchEvent(new Event('UploadError', true));
        }

        private function ioErrorHandler(event:IOErrorEvent):void 
        {
        	if (this.Mode == "Download")
        	{
          		this.ErrorMessage = RM('FileTransferIOWriteError');
				this.dispatchEvent(new Event('DownloadError', true));
        	}
        	else
        	{
          		this.ErrorMessage = RM('FileTransferIOReadError');
				this.dispatchEvent(new Event('UploadError', true));
        	}
        }
        private function selectHandler(event:Event):void 
        {
        	if (this.Mode == "Upload")
        	{
        		this.LocalFileName = this.name;
	        	this.load ();
        	}
        }
        private function completeHandler(event:Event):void 
        {
        	if (this.Mode == "Upload")
        	{
        		this.TotBytes = this.data.length;
				this.FileUOper1.send(this.ContextId);
				this.dispatchEvent(new Event('UploadBegin', true));
        	}
        	if (this.Mode == "Download")
        	{
				this.dispatchEvent(new Event('DownloadSaved', true));
        		this.WorkDone = true;
        	}
        }
        private function OnFileUInfo(e:ResultEvent):void
        {
           	this.HostFileName = e.result.HostFileName;
           	if (e.result.OutMessage != "")
           	{
           		this.ErrorMessage = e.result.OutMessage;
				this.dispatchEvent(new Event('UploadError', true));
				this.CancelUpload();
           	}	
            else
            {
            	var loadsize:int;
            	loadsize = this.ChunkSize;
            	if (this.TotBytes < this.ChunkSize) loadsize = this.TotBytes;
       	    	this.data.position = 0;
       	    	this.trData.clear();
            	this.data.readBytes (this.trData, 0, loadsize);
            	if (this.WorkCanceled == false)
            		this.FileUOper2.send (this.ContextId, this.HostFileName, this.trData);
				else
				{
					this.FileDelOper.send (this.ContextId, this.HostFileName);
					this.dispatchEvent(new Event('UploadCanceled', true));
				}
            }		
        }
        private function OnFileUData(e:ResultEvent):void
        {
            this.TrBytes = e.result.HostFileSize;
            if (e.result.OutMessage != "")
            {
           		this.ErrorMessage = e.result.OutMessage;
				this.dispatchEvent(new Event('UploadError', true));
				this.CancelUpload();
            }	
            else
            {
            	if (this.TrBytes >= this.TotBytes)
            	{
					this.WorkDone = true;
					this.dispatchEvent(new Event('UploadComplete', true));
	            }
            	else
            	{
					this.dispatchEvent(new Event('UploadProgress', true));

	            	var loadsize:int;
    	        	loadsize = this.ChunkSize;
        	    	if (this.TotBytes - this.TrBytes < this.ChunkSize) loadsize = this.TotBytes - this.TrBytes;
        	    	this.data.position = this.TrBytes;
	       	    	this.trData.clear();
            		this.data.readBytes (this.trData, 0, loadsize);
	            	if (this.WorkCanceled == false)
    	        		this.FileUOper2.send (this.ContextId, this.HostFileName, this.trData);
					else
					{
						this.FileDelOper.send (this.ContextId, this.HostFileName);
						this.dispatchEvent(new Event('UploadCanceled', true));
					}
            	}
           	}
        }
        private function OnFileDelete (e:ResultEvent):void
        {
        	if (e.result.OutMessage == "")
        	{
				this.dispatchEvent(new Event('FileDeleted', true));
	           	this.HostFileName = "";
        	}
        } 
	}
}