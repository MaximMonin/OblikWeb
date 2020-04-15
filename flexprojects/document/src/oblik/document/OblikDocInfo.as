package oblik.document
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import mx.collections.ArrayCollection;
	import mx.controls.DataGrid;
	import mx.controls.TextArea;
	import mx.controls.TileList;

	public class OblikDocInfo extends Object
	{
        /* Ключ объекта */
        public var DocsId:int;

        public var dg:DataGrid;
        public var MessageArea:TextArea;

        public var InfoType:String;
        public var RidDoc:int;
        public var ViewOnly:Boolean;
        public var putoff:Boolean;

        public var DocInfo:Array;
        public var DocData:ArrayCollection;

        public var LoadArea:TileList;
        public var LoadList:ArrayCollection;
        public var AllLoadList:ArrayCollection;

		public function OblikDocInfo()
		{
			super();
			this.LoadList = new ArrayCollection ();
			this.AllLoadList = new ArrayCollection ();
		}
		
	}
}