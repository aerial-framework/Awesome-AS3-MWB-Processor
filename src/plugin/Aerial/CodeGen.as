package plugin.Aerial
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
		
		public var modelPackage:String;
		public var servicePackage:String;
		public var bootstrapPackage:String;
		public var modelSuffix:String = "VO";
		public var serviceSuffix:String = "Service";
		public var fw:FileWriter;
		
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
				codegenEvent.fileName = table.className + "Service" + ".php";
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
			var dkName:String;
			
			for each (table in schema.tables)
			{
				if(tables && (tables.indexOf(table.name) == -1))
					continue;
				
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
					fw.add("private var _" + fk.referencedTable.className + ":*;").newLine();
				}
				
				//Private vars: Many
				for each(dk in table.domesticKeys)
				{
					fw.add("private var _"+ Inflector.pluralCamelize(dk.referencedTable.className) + ":*;").newLine();
				}
				
				//Getters & Setters
				for each (column in table.columns)
				{
					fw.newLine();
					
					fw.add("public function get "+ column.name +"():" + getAS3Type(column.rawType)).newLine();
					fw.add("{").newLine().indentForward();
					fw.add("return _" + column.name).newLine().indentBack();
					fw.add("}").newLine(2);
					
					fw.add("public function set "+ column.name +"(value:XXX):void").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("_" + column.name + " = value;").newLine().indentBack();
					fw.add("}").newLine();
				}
				
				//Getters & Setters: One
				for each(fk in table.foreignKeys)
				{
					fw.newLine();
					
					fw.add("public function get "+ fk.referencedTable.className +"():"+ fk.referencedTable.className + this.modelSuffix +"").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("return _"+ fk.referencedTable.className +";").newLine().indentBack();
					fw.add("}").newLine(2);
					
					fw.add("public function set "+ fk.referencedTable.className +"(value:"+fk.referencedTable.className + this.modelSuffix+"):void").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("_"+ fk.referencedTable.className +" = value;").newLine().indentBack();
					fw.add("}").newLine();
				}
				
				//Getters & Setters: Many
				for each(dk in table.domesticKeys)
				{
					dkName = Inflector.pluralCamelize(dk.referencedTable.className);
					fw.newLine();
					
					fw.add("public function get "+ dkName +"():ArrayCollection").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("return _" +  dkName + ";").newLine().indentBack();
					fw.add("}").newLine(2);
					
					fw.add("public function set "+ dkName +"(value:ArrayCollection):void").newLine();
					fw.add("{").newLine().indentForward();
					fw.add("_" + dkName + " = value;").newLine().indentBack();
					fw.add("}").newLine();
				}
				
				fw.indentBack().add("}").newLine().indentBack().add("}");
				
				
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