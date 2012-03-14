package plugin.doctrine
{
	import com.mysql.workbench.Inflector;
	import com.mysql.workbench.YamlWriter;
	import com.mysql.workbench.model.Column;
	import com.mysql.workbench.model.ForeignKey;
	import com.mysql.workbench.model.Index;
	import com.mysql.workbench.model.RelationKey;
	import com.mysql.workbench.model.Schema;
	import com.mysql.workbench.model.Table;
	
	public class YamlGen
	{
		public var schema:Schema;
		
		public function YamlGen(schema:Schema)
		{
			if(schema)
				this.schema = schema;
		}
		
		public function generateYaml(tables:Array = null):String
		{
			var yaml:YamlWriter = new YamlWriter(); //YamlWriter.getInstance();
			yaml.addKeyValue("detect_relations", true);
			yaml.addNode("options");
			yaml.addKeyValue("collate", schema.defaultCollationName);
			yaml.addKeyValue("charset", schema.defaultCharacterSetName);
			yaml.addKeyValue("type", "InnoDB");
			yaml.closeNode();
			yaml.addLineBreak();
			
			for each (var table:Table in schema.tables)
			{
				yaml.addNode(table.className);
				yaml.addKeyValue("tableName", table.name);
				
				if(table.columns.length > 0)
					yaml.addNode("columns");
				for each (var column:Column in table.columns)
				{
					yaml.addNode(column.name);
					if(column.name != column.propertyName)
						yaml.addKeyValue("name", column.name + " as " + column.propertyName);
					yaml.addKeyValue("type", column.type);
					if(column.isPrimary)
						yaml.addKeyValue("primary", column.isPrimary);
					if(column.isNotNull == true)
						yaml.addKeyValue("notnull", column.isNotNull);
					if(column.autoIncrement == true)
						yaml.addKeyValue("autoincrement", column.autoIncrement);
					if(column.defaultValue)
						yaml.addKeyValue("default", column.defaultValue);
					yaml.closeNode();//Column End
				}
				yaml.closeNode();//Columns End
				
				if(table.foreignKeys.length > 0 || table.relations.length > 0)
					yaml.addNode("relations");
				for each(var fk:ForeignKey in table.foreignKeys)
				{  
					yaml.addNode(fk.columnClassName);
					yaml.addKeyValue("class", fk.referencedTable.className);
					yaml.addKeyValue("local", fk.column.name);
					yaml.addKeyValue("foreign", fk.referencedColumn.name);
					yaml.addKeyValue("foreignAlias", Inflector.pluralCamelize(table.className)); 
					yaml.closeNode();//FK's End
				}
				for each(var rel:RelationKey in table.relations)
				{
					yaml.addNode(rel.relationName);
					yaml.addKeyValue("class", rel.referencedTable.className);
					yaml.addKeyValue("local", rel.joinLocal.name);
					yaml.addKeyValue("foreign", rel.joinForeign.name);
					yaml.addKeyValue("foreignAlias", rel.foreignAlias);
					yaml.addKeyValue("refClass", rel.joinTable.className);
					yaml.closeNode();//Relation Helpers End
				}
				yaml.closeNode();//Relations End
				
				var addedIndexNode:Boolean = false;
				for each(var index:Index in table.indices)
				{  
					if(index.indexType == "INDEX")
					{
						if(!addedIndexNode)
						{
							addedIndexNode = true;
							yaml.addNode("indexes");
						}
						yaml.addNode(index.name);
						var colArray:Array = new Array();
						for each(var col:Column in index.columns)
						{
							colArray.push(col.name);
						}
						yaml.addKeyValue("fields", "[" + colArray.join(", ") + "]");
						yaml.closeNode();//Index End
					}
				}
				yaml.closeNode();//Indexes End
				
				yaml.closeNode();//Table End
				yaml.addLineBreak(); 
			}
			return yaml.stream;
		}
		
	}
}