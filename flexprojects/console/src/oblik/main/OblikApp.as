package oblik.main
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import mx.collections.ArrayCollection;
	import mx.containers.Grid;
	import mx.controls.ComboBox;
	import mx.controls.TextInput;
	import mx.controls.TileList;
	import mx.controls.Tree;
	import mx.rpc.soap.Operation;
	import mx.rpc.soap.WebService;
	
	public class OblikApp extends Object
	{
        public var AppsId:int;
        /* Ссылки на элементы формы */
        public var login:TextInput;
        public var db:TextInput;
        public var ent:ComboBox;
        public var cathg:ComboBox;
        public var app:ComboBox;
        public var mainmenu:Tree;
        public var fastmenu:TileList;
 
        /* Параметры связи с Web Сервис */
        public var serviceURL:String;
        public var ws:WebService;
        public var GetAvailApps:Operation;
        public var GetMenu:Operation;
        public var runModule:Operation;
        public var ContextId:String;
        public var ServiceId:int;
        public var appDP:ArrayCollection;
        public var appResult:ArrayCollection;
 
        /* Текущий режим */
        public var uid:String;
        public var rident:int;
        public var ridcathg:int;
        public var ridapp:int;

		public function OblikApp()
		{
			super();
		}
		
	}
}