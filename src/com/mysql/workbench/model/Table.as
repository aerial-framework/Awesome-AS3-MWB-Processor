package com.mysql.workbench.model
{
	import com.mysql.workbench.Inflector;
	import com.mysql.workbench.model.base.Base;
	
	public class Table extends Base
	{
		public var name:String;
		public var className:String;
		public var columns:Array;
		public var primaryKey:PrimaryKey
		public var foreignKeys:Array;
		public var domesticKeys:Array;
		public var indices:Array;
		public var relations:Array;
		public var engine:String;
		
		
		public function Table(xml:XML)
		{
			super(xml);
			name = String(xml.value.(@key=='name'));
			className = Inflector.singularPascalize(name);
			columns = new Array();
			primaryKey = new PrimaryKey();
			foreignKeys = new Array();
			domesticKeys = new Array();
			indices = new Array();
			relations = new Array();
			engine = String(xml.value.(@key=='tableEngine'));
			
			/*Set Columns*/
			var xmlColumns:XMLList = xml.value.(@key=='columns').value;
			for each(var xmlColumn:XML in xmlColumns)
			{
				columns.push(new Column(xmlColumn));
			}
		}
		
		public function loadForeignKeys():void
		{
			var xmlFKs:XMLList = xml.value.(@key=='foreignKeys').value;
			for each(var xmlFK:XML in xmlFKs)
			{
				foreignKeys.push(new ForeignKey(xmlFK));
			}
		}
		
		public function loadDomesticKeys():void
		{
			for each(var fk:ForeignKey in foreignKeys)
			{
				fk.referencedTable.domesticKeys.push(new DomesticKey(fk.referencedColumn, this, fk.column));
			}
		}
		
		public function loadIndices():void
		{
			var xmlIndices:XMLList = xml.value.(@key=='indices').value;
			for each(var xmlIndex:XML in xmlIndices)
			{
				var index:Index = new Index(xmlIndex);
				indices.push(index);
				if(index.isPrimary)
					this.primaryKey.columns = index.columns;
			}
		}
		
	}
}