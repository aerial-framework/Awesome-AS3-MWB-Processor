package com.mysql.workbench.model
{
	public class DomesticKey
	{
		public function DomesticKey(column:Column=null, referencedTable:Table=null, referencedColumn:Column=null)
		{
			if(column) this.column = column;
			if(referencedTable) this.referencedTable = referencedTable;
			if(referencedColumn) this.referencedColumn = referencedColumn;
		}
		
		public var column:Column;
		public var referencedTable:Table;
		public var referencedColumn:Column;
	}
}