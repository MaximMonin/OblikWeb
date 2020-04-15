package oblik.document
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import mx.collections.ArrayCollection;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.DataGrid;
	import mx.controls.LinkButton;
	import mx.controls.TextArea;
	import mx.controls.TileList;
	
	import oblik.basetype.OblikBasetype;
	import oblik.basetype.OblikDate;
	import oblik.basetype.OblikInteger;
	import oblik.basetype.OblikSelList;

	public class OblikDocs extends Object
	{
        /* Ключ объекта */
        public var DocsId:int;
        /* Ссылки на элементы формы */
        public var morefilter:LinkButton;
        public var newdoc:LinkButton;
        public var idtypedoc:OblikBasetype;
        public var scope:OblikSelList;
        public var datefrom:OblikDate;
        public var dateto:OblikDate;
        public var MaxRecCount:OblikInteger;
        public var gobutton:Button;
        public var dg:DataGrid;
        public var MessageArea:TextArea;
        public var AddFilterArea:VBox;
        public var LoadArea:TileList;
        public var LoadList:ArrayCollection;
        public var AllLoadList:ArrayCollection;
        public var PutOff:OblikSelList;
        public var IdDoc:OblikInteger;
        public var RidDoc:OblikInteger;
        public var ViewOnly:Boolean;
        
        public var FieldsSel:ComboBox;
        public var ClearFilter:Button;
        public var AddFilter:Button;
        public var FieldValue:Object;
        public var FilterGrid:DataGrid;
        public var DataFilter:ArrayCollection;
        public var Fields:ArrayCollection;
 
        /* Выбранные значения */
        public var ridtypedoc:int;
        public var ridapp:int;
        public var putoff:Boolean;
        
        public var DocInfo:Array;
        public var DocData:ArrayCollection;

		public function OblikDocs()
		{
			super();
			this.DataFilter = new ArrayCollection ();
			this.LoadList = new ArrayCollection ();
			this.AllLoadList = new ArrayCollection ();
		}
		
	}
}