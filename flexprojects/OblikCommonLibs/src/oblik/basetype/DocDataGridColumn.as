package oblik.basetype
{

// Copyright (C) Maxim A. Monin 2009-2010 

	import mx.controls.dataGridClasses.DataGridColumn;

	public class DocDataGridColumn extends DataGridColumn
	{
		public var InternalDataField:String;
	
		public function DocDataGridColumn(columnName:String=null)
		{
			super(columnName);
			InternalDataField = null;
		}
		
	}
}