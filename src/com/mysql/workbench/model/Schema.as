package com.mysql.workbench.model
{
	import com.mysql.workbench.Inflector;
	import com.mysql.workbench.YamlWriter;
	
	public class Schema
	{
		public var name:String;
		public var tables:Array;
		public var views:Array;
		public var defaultCollationName:String;
		public var defaultCharacterSetName:String;
		
		
		public function Schema(xml:XML = null)
		{
			/*Set Schema name*/
			name = String(xml.value.(@key=='name'));
			defaultCollationName = String(xml.value.(@key=='defaultCollationName'));
			defaultCharacterSetName = String(xml.value.(@key=='defaultCharacterSetName'));
			tables = new Array();
			views = new Array();
			
			/*Set Tables & Columns*/
			var xmlTables:XMLList = xml.value.(@key=='tables').value;
			for each(var xmlTable:XML in xmlTables)
			{
				tables.push(new Table(xmlTable));
			}
			
			/*Set PK', ForeignKeys & DomesticKeys*/
			var table:Table;
			for each(table in tables)
			{
				table.loadForeignKeys();
				table.loadIndices();
				table.loadDomesticKeys();
			}
			
			/*Set Views*/  //Not implemented yet
			var xmlViews:XML = xml.value.(@key=='views')[0];
			for each(var xmlView:XML in xmlViews)
			{
				views.push(new View(xmlView));
			}
		}
		
	}
}