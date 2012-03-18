package plugin.aerial
{
	import com.mysql.workbench.FileWriter;
	import com.mysql.workbench.Inflector;
	import com.mysql.workbench.model.Column;
	import com.mysql.workbench.model.DomesticKey;
	import com.mysql.workbench.model.ForeignKey;
	import com.mysql.workbench.model.Schema;
	import com.mysql.workbench.model.Table;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import plugin.events.CodeGenEvent;
	
	public class CodeGen extends EventDispatcher
	{
		public static const MODEL:String = "model";
		public static const SERVICE:String = "service";
		
		private var schema:Schema;
		public var fw:FileWriter;
		
		public var modelPackage:String;
		public var servicePackage:String;
		public var bootstrapPackage:String;
		public var modelSuffix:String = "VO";
		public var serviceSuffix:String = "Service";
		public var relationships:XML;
		
		public function CodeGen(schema:Schema)
		{
			if(schema)
				this.schema = schema;
			
			fw = new FileWriter();
		}
		
		public function generateServices(tables:Array=null):void
		{
			if(!servicePackage || !modelPackage)
				throw new Error("'servicePackage' or 'modelPackage' are not set.");	
			
			var table:Table
			var serviceClass:String;
			var modelClass:String;
			for each (table in schema.tables)
			{
				if(tables && (tables.indexOf(table.name) == -1))
					continue;
				
				serviceClass = table.className + this.serviceSuffix;
				modelClass = table.className + this.modelSuffix;
				
				fw.clear();
				fw.add('package ' + this.servicePackage).newLine();
				fw.add("{").newLine().indentForward();
				fw.add("import org.aerialframework.rpc.AbstractService;").newLine(2);
				fw.add("import "+ this.modelPackage +"."+ modelClass +";").newLine();
				fw.add("import "+ this.bootstrapPackage +".Aerial;").newLine(2);
				fw.add("public class "+ serviceClass +" extends AbstractService").newLine();
				fw.add("{").newLine().indentForward();
				fw.add("public function "+ serviceClass +"()").newLine();
				fw.add("{").newLine().indentForward();
				fw.add('super("'+serviceClass+'", Aerial, '+ modelClass +');').newLine().indentBack();
				fw.add("}").newLine().indentBack();
				fw.add("}").newLine().indentBack();
				fw.add("}").newLine();
				
				//Dispatch CodeGen Event
				var codegenEvent:CodeGenEvent = new CodeGenEvent(CodeGenEvent.CREATED);
				
				codegenEvent.fileType = CodeGen.SERVICE;
				codegenEvent.filePackage = this.servicePackage;
				codegenEvent.fileName = table.className + "Service" + ".as";
				codegenEvent.fileContent = fw.stream;
				
				dispatchEvent(codegenEvent);
			}
		}
		
		public function generateModels(tables:Array = null):void
		{
			if(!modelPackage || !modelSuffix)
				throw new Error("'modelPackage' or 'modelSuffix' are not set.");	
			
			//loop vars
			var column:Column;
			var fk:ForeignKey;
			var dk:DomesticKey;
			var table:Table
			var tmpName:String;
			var as3Type:String;
			var t1:XML;
			var t2:XML
			var xmlMN:XML;
			var xmlSelf:XML;
			var xmlFK:XML
			var alias:String;
			var aliases:Array = new Array();
			
			for each (table in schema.tables)
			{
				if(tables && (tables.indexOf(table.name) == -1))
					continue;
				
				var tableName:String = table.name; //e4x var

				fw.clear();
				fw.add("package " + modelPackage).newLine();
				fw.add("{").newLine().indentForward();
				fw.add("import org.aerialframework.rpc.AbstractVO;").newLine();
				fw.add("import "+this.modelPackage+".*;").newLine(2);
				fw.add("import flash.events.Event;").newLine();
				fw.add("import mx.collections.ArrayCollection;").newLine();
				fw.add("import flash.utils.ByteArray;").newLine(2);
				fw.add("[Bindable]").newLine();
				fw.add('[RemoteClass(alias="'+ this.modelPackage +"."+ table.className +'")]').newLine();
				fw.add("public class "+ table.className + this.modelSuffix +" extends AbstractVO").newLine();
				fw.add("{").newLine().indentForward();
				fw.add("public function "+table.className + this.modelSuffix+"()").newLine();
				fw.add("{").newLine().indentForward();
				fw.add("super(function(field:String):*{return this[field]},").newLine().indentForward();
				fw.add("function(field:String, value:*):void{this[field] = value});").newLine().indentBack(2);
				fw.add("}").newLine(2);
				
				//Private vars
				for each (column in table.columns)
				{
					fw.add("private var _" + column.name + ":*;").newLine();
				}
				
				//Private vars: One 
				for each(fk in table.foreignKeys)
				{
					fw.add("private var _" + fk.columnClassName + ":*;").newLine();
				}
				
				//Private vars: Many
				aliases = new Array();
				for each(dk in table.domesticKeys)
				{
					//There's a possibility of repeating aliases in cases like self referencing using a refClass.
					alias = Inflector.pluralCamelize(dk.referencedTable.className);
					if(!aliases["_" + alias])
						aliases["_" + alias] = 1;
					else
						aliases["_" + alias]++;
					tmpName = alias + (aliases["_" + alias] > 1 ? aliases["_" + alias] : "" );

					fw.add("private var _"+ tmpName + ":*;").newLine();
				}

				//Private vars: Custom Many
				for each(xmlMN in relationships.mn.(table.(text() == tableName).parent()))
				{
					t1 = xmlMN.table.(text() == tableName)[0];
					t2 = xmlMN.table.(text() != tableName)[0];
					alias = (t2.attribute("alias").length() > 0 ? t2.attribute("alias") : t2.text());

					fw.add("private var _"+ Inflector.pluralCamelize(alias) + ":*;").newLine();
				}

				//Private vars: Custom Self
				for each(xmlSelf in relationships.self.(@table == tableName))
				{
					for each(xmlFK in xmlSelf.fk)
					{
						fw.add("private var _"+ Inflector.pluralCamelize(xmlFK.@alias) + ":*;").newLine();
					}
				}
				
				//Getters & Setters
				for each (column in table.columns)
				{
					fw.newLine();
					as3Type = getAS3Type(column.rawType);

					fw.add("public function get "+ column.name +"():" + as3Type).newLine();
					fw.add("{").newLine().indentForward();
					fw.add("return _" + column.name).newLine().indentBack();
					fw.add("}").newLine(2);
					
					fw.add("public function set "+ column.name +"(value:"+ as3Type +"):void").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("_" + column.name + " = value;").newLine().indentBack();
					fw.add("}").newLine();
				}
				
				//Getters & Setters: One
				for each(fk in table.foreignKeys)
				{
					fw.newLine();
					
					fw.add("public function get "+ fk.columnClassName +"():"+ fk.referencedTable.className + this.modelSuffix +"").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("return _"+ fk.columnClassName +";").newLine().indentBack();
					fw.add("}").newLine(2);
					
					fw.add("public function set "+ fk.columnClassName +"(value:"+fk.referencedTable.className + this.modelSuffix+"):void").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("_"+ fk.columnClassName +" = value;").newLine().indentBack();
					fw.add("}").newLine();
				}
				
				//Getters & Setters: Many
				aliases = new Array();
				for each(dk in table.domesticKeys)
				{
					//There's a possibility of repeating aliases in cases like self referencing using a refClass.
					alias = Inflector.pluralCamelize(dk.referencedTable.className);
					if(!aliases["_" + alias])
						aliases["_" + alias] = 1;
					else
						aliases["_" + alias]++;
					
					tmpName = alias + (aliases["_" + alias] > 1 ? aliases["_" + alias] : "" );
					fw.newLine();
					
					fw.add("public function get "+ tmpName +"():ArrayCollection").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("return _" +  tmpName + ";").newLine().indentBack();
					fw.add("}").newLine(2);
					
					fw.add("public function set "+ tmpName +"(value:ArrayCollection):void").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("_" + tmpName + " = value;").newLine().indentBack();
					fw.add("}").newLine();
				}
				
				//Custom Relationships: Many
				for each(xmlMN in relationships.mn.(table.(text() == tableName).parent()))
				{
					t1 = xmlMN.table.(text() == tableName)[0];
					t2 = xmlMN.table.(text() != tableName)[0];
					alias = (t2.attribute("alias").length() > 0 ? t2.attribute("alias") : t2.text());

					tmpName = Inflector.pluralCamelize(alias);
					fw.newLine();
					fw.add("public function get "+ tmpName +"():ArrayCollection").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("return _" +  tmpName + ";").newLine().indentBack();
					fw.add("}").newLine(2);

					fw.add("public function set "+ tmpName +"(value:ArrayCollection):void").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("_" + tmpName + " = value;").newLine().indentBack();
					fw.add("}").newLine();
				}

				//Custom Relationships: Self
				for each(xmlSelf in relationships.self.(@table == tableName))
				{
					for each(xmlFK in xmlSelf.fk)
					{
						tmpName = Inflector.pluralCamelize(xmlFK.@alias);
						fw.newLine();
						fw.add("public function get "+ tmpName +"():ArrayCollection").newLine();
						fw.add("{").newLine().indentForward();
						fw.add("return _" +  tmpName + ";").newLine().indentBack();
						fw.add("}").newLine(2);

						fw.add("public function set "+ tmpName +"(value:ArrayCollection):void").newLine();
						fw.add("{").newLine().indentForward();
						fw.add("_" + tmpName + " = value;").newLine().indentBack();
						fw.add("}").newLine();
					}
				}
				
				fw.indentBack().add("}").newLine().indentBack().add("}"); //Close class
				
				//Dispatch CodeGen Event
				var codegenEvent:CodeGenEvent = new CodeGenEvent(CodeGenEvent.CREATED);
				
				codegenEvent.fileType = CodeGen.MODEL;
				codegenEvent.filePackage = this.modelPackage;
				codegenEvent.fileName = table.className + this.modelSuffix + ".as";
				codegenEvent.fileContent = fw.stream;
				
				dispatchEvent(codegenEvent);
			}	
		}
	
		public function getAS3Type(type:String, unsigned:Boolean=false):String
		{
			var as3type:String = "";
			switch (type)
			{
				case 'integer':
					as3type = unsigned ? "uint" : "int";
					break;
				case 'decimal':
				case 'float':
				case 'double':
					as3type = "Number";
					break;
				case 'set':
				case 'array':
					as3type = "Array";
					break;
				case 'boolean':
					as3type = "Boolean";
					break;
				case 'blob':
					as3type = "ByteArray";
					break;
				case 'object':
					as3type = "Object";
					break;
				case 'time':
				case 'timestamp':
				case 'date':
				case 'datetime':
					as3type = "Date";
					break;
				case 'enum':
				case 'gzip':
				case 'string':
				case 'clob':
					as3type = "String";
					break;
				default:
					as3type = type;
					break;
			}
			
			return as3type;
		}
		
	}
}