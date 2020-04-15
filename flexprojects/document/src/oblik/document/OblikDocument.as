package oblik.document
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import mx.collections.ArrayCollection;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.ProgressBar;
	
	public class OblikDocument extends Object
	{
        /* Ключ объекта */
        public var DocsId:int;
        public var RidDoc:int;
        public var RidTypedoc:int;
        public var rootframe:VBox;
        public var Frames:ArrayCollection;
        public var Fields:Array;
        public var DG:ArrayCollection;
        public var DF:ArrayCollection;
        public var loadedFrames:int;
        public var pb:ProgressBar;
        public var EditButton:Button;
        public var PrintButton:Button;

        public var ViewOnly:Boolean;
        public var putoff:Boolean;

		public function OblikDocument()
		{
			super();
		}
		
	}
}