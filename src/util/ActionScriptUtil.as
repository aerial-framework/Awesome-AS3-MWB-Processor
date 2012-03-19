package util
{
	public class ActionScriptUtil
	{
		public static function getAS3Type(type:String, unsigned:Boolean=false):String
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