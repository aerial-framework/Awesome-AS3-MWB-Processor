package plugin.Aerial
{
	import com.mysql.workbench.FileWriter;
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
	}
}