package plugin.doctrine
{
	import com.mysql.workbench.FileWriter;
	import com.mysql.workbench.Inflector;
	import com.mysql.workbench.model.Column;
	import com.mysql.workbench.model.DomesticKey;
	import com.mysql.workbench.model.ForeignKey;
	import com.mysql.workbench.model.Index;
	import com.mysql.workbench.model.Schema;
	import com.mysql.workbench.model.Table;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.utils.StringUtil;
	
	import plugin.events.CodeGenEvent;
	
	public class CodeGen extends EventDispatcher
	{
		public static const BASE_MODEL:String = "baseModel";
		public static const MODEL:String = "model";
		public static const SERVICE:String = "service";
		
		private var schema:Schema;
		
		public var modelPackage:String;
		public var servicePackage:String;
		public var baseModelFolderName:String = "base";
		public var fw:FileWriter;
		
		public function CodeGen(schema:Schema)
		{
			if(schema)
				this.schema = schema;
			
			fw = new FileWriter();
		}
		
		public function generateServices(tables:Array=null):void
		{
			if(!servicePackage)
				throw new Error("'servicePackage' not set.");	
			
			var table:Table
			for each (table in schema.tables)
			{
				if(tables && (tables.indexOf(table.name) == -1))
					continue;
				fw.clear();
				fw.add('<?php').newLine();
				fw.indentForward().add('import("aerialframework.service.AbstractService");').newLine(2);
				fw.add('class ' + table.name + 'Service extends AbstractService').newLine().add('{').newLine();
				fw.indentForward().add('public $modelName = "'+ table.className +'";').newLine();
				fw.indentBack().add('}').newLine();
				fw.indentBack().add('?>').newLine(3);
				
				var codegenEvent:CodeGenEvent = new CodeGenEvent(CodeGenEvent.CREATED);
				
				codegenEvent.fileType = CodeGen.SERVICE;
				codegenEvent.filePackage = this.servicePackage;
				codegenEvent.fileName = table.className + "Service" + ".php";
				codegenEvent.fileContent = fw.stream;
				
				dispatchEvent(codegenEvent);
			}
		}
		
		public function generateModels(tables:Array=null):void
		{
			generateSubClassModels(tables);
			generateBaseModels(tables);
		}
		
		public function generateSubClassModels(tables:Array=null):void
		{
			if(!modelPackage)
				throw new Error("'modelPackage' not set.");	
			
			var table:Table
			for each (table in schema.tables)
			{
				if(tables && (tables.indexOf(table.name) == -1))
					continue;
				fw.clear();
				fw.add('<?php').newLine(2);
				fw.add('class ' + table.className + ' extends ' + Inflector.ucfirst(this.baseModelFolderName) + table.className).newLine();
				fw.add('{').newLine(2);
				fw.add('}')
				
				//Dispatch an event containing the generated content.
				var codegenEvent:CodeGenEvent = new CodeGenEvent(CodeGenEvent.CREATED);
				
				codegenEvent.fileType = CodeGen.MODEL;
				codegenEvent.filePackage = this.modelPackage;
				codegenEvent.fileName = table.className + ".php";
				codegenEvent.fileContent = fw.stream;
				
				dispatchEvent(codegenEvent);
			}
		}
		
		public function generateBaseModels(tables:Array=null):void
		{
			if(!modelPackage)
				throw new Error("'modelPackage' not set.");	
			
			var table:Table
			for each (table in schema.tables)
			{
				if(tables && (tables.indexOf(table.name) == -1))
					continue;
				
				fw.clear();
				fw.add('<?php').newLine(2);
				fw.add('abstract class '+ Inflector.ucfirst(this.baseModelFolderName) + table.className +' extends Aerial_Record').newLine();
				fw.add('{').newLine().indentForward();
				fw.add('public function setTableDefinition()').newLine();
				fw.add('{').newLine().indentForward();
				fw.add("$this->setTableName('"+ table.name +"');").newLine();
				
				//Properties
				for each (var column:Column in table.columns)
				{
					fw.add("$this->hasColumn('"+ column.name +"', '"+column.rawType+"', "+column.typeLength+", array(").newLine().indentForward();
					fw.add("'type' => '"+column.rawType+"',").newLine();
					if(column.type == "enum")
					{
						fw.add("'values' =>").newLine().add("array(").newLine();
						var enums:Array  = String(column.dataTypeExplicitParams.match(/(?<=\().*(?=\))/).shift()).split(",");						
						for (var i:int = 0; i < enums.length; i++) 
						{
							fw.add(" "+ i.toString() +" => "+ enums[i]+",").newLine();
						}
						fw.add("),").newLine();
					}
					if(column.isPrimary)
						fw.add("'primary' => true,").newLine();
					if(column.autoIncrement)
						fw.add("'autoincrement' => true,").newLine();
					if(column.isNotNull && !column.isPrimary)
						fw.add("'notnull' => true,").newLine();
					if(column.isUnique && !column.isPrimary)
						fw.add("'unique' => true,").newLine();
					//Default value is a mess in MWB because of system constants.  Strings can be entered w/ or w/o quotes.
					//i.e., CURRENT_TIMESTAMP and 'pending'
					if(column.defaultValue && isNaN(Number(column.defaultValue)))
						fw.add("'default' => '"+ column.defaultValue +"',").newLine();
					else if(column.defaultValue)
						fw.add("'default' => "+ column.defaultValue +",").newLine();
					if(column.typeLength)
						fw.add("'length' => '"+column.typeLength+"',").newLine();
					fw.add("));").newLine().indentBack();
				}
				fw.newLine();
				
				//Indexes
				for each(var index:Index in table.indices)
				{  
					if(index.indexType != "INDEX")
						continue;
					fw.add("$this->index('"+ index.name +"', array(").newLine().indentForward();
					fw.add("'fields' => ").newLine();
					fw.add("array(").newLine();
					for (var j:int = 0; j < index.columns.length; j++) 
					{
						fw.add(" 0 => '"+Column(index.columns[j]).name+"',").newLine();
					}
					fw.add("),").newLine();
					fw.add("));").newLine().indentBack();
				}
				fw.newLine();
				
				//Collation
				fw.add("$this->option('collate', '"+ schema.defaultCollationName +"');").newLine();
				fw.add("$this->option('charset', '"+ schema.defaultCharacterSetName +"');").newLine();
				fw.add("$this->option('type', '"+ table.engine +"');").newLine().indentBack();
				
				fw.add("}").newLine(2);
				
				//Relationships
				fw.add("public function setUp()").newLine();
				fw.add("{").newLine().indentForward();
				fw.add("parent::setUp();").newLine();
				
				for each(var fk:ForeignKey in table.foreignKeys)
				{  
					fw.add("$this->hasOne('" + fk.columnClassName
						+(fk.columnClassName != fk.referencedTable.className ? " as "+ fk.referencedTable.className : "")
						+"', array(").newLine().indentForward();
					fw.add("'local' => '"+ fk.column.name +"',").newLine();
					fw.add("'foreign' => '"+ fk.referencedColumn.name +"'));").newLine().indentBack();
				}
				
				for each(var dk:DomesticKey in table.domesticKeys)
				{
					fw.add("$this->hasMany('"+ dk.referencedTable.className +" as "+Inflector.pluralCamelize(dk.referencedTable.className)+"', array(").newLine().indentForward();
					fw.add("'local' => '"+ Column(table.primaryKey.columns[0]).name +"',").newLine();
					fw.add("'foreign' => '"+ dk.referencedColumn.name +"'));").newLine().indentBack();
				}
				fw.indentBack().add("}").newLine(2);
				
				//_explicitType
				fw.add("public function construct()").newLine();
				fw.add("{").newLine().indentForward();
				fw.add("$this->mapValue('_explicitType', '"+this.modelPackage+"."+table.className+"');").newLine().indentBack();
				fw.add("}").newLine().indentBack();
				
				fw.add("}");
				
				//Dispatch an event containing the generated content.
				var codegenEvent:CodeGenEvent = new CodeGenEvent(CodeGenEvent.CREATED);
				
				codegenEvent.fileType = CodeGen.BASE_MODEL;
				codegenEvent.filePackage = this.modelPackage + "." + this.baseModelFolderName;
				codegenEvent.fileName = Inflector.ucfirst(this.baseModelFolderName) + table.className + ".php";
				codegenEvent.fileContent = fw.stream;
				
				dispatchEvent(codegenEvent);
			}//End Table Loop
		}
		
	}
}