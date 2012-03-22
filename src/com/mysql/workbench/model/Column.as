package com.mysql.workbench.model
{
	import com.mysql.workbench.DatatypeConverter;
	import com.mysql.workbench.Inflector;
	import com.mysql.workbench.model.base.Base;
	
	public class Column extends Base
	{
		public var name:String;
		public var propertyName:String;
		public var type:String;
		public var autoIncrement:Boolean = false;
		public var defaultValue:String;
		public var isNotNull:Boolean = false;
		public var isPrimary:Boolean = false;
		public var isUnsigned:Boolean = false;
		public var isZeroFill:Boolean = false;
		public var dataTypeExplicitParams:String;
		public var owner:Table;
		
		public function Column(xml:XML)
		{
			super(xml);
			
			name = xml.value.(@key=='name');
			propertyName = Inflector.singularCamelize(name);
			for each(var xmlFlag:XML in xml.value.(@key=='flags').value)
			{
				switch (String(xmlFlag.text()))
				{
					case "UNSIGNED":
						isUnsigned = true;
						break;
					
					case "ZEROFILL":
						isZeroFill = true;
						break;
				}
			}
			type = xml.link.(@key == 'simpleType');
			if(!type)
				type = xml.link.(@key == 'userType');
			type = DatatypeConverter.getDataType(type);
			isNotNull = Boolean(int(xml.value.(@key=='isNotNull')));
			autoIncrement = Boolean(int(xml.value.(@key=='autoIncrement')));
			defaultValue = String(xml.value.(@key == 'defaultValue')).replace(/(?:\s*["|'])?(.*)(?:"|')/,'$1');//Strip out single & double quote wrappers.
			dataTypeExplicitParams = xml.value.(@key == 'datatypeExplicitParams');
			var typeLength:int = int(xml.value.(@key == 'length'));
			if(typeLength != -1)
				type += "(" + String(typeLength) + ")";
			
			var ownerId:String = XMLList(xml.link.(@key=="owner")).toString();
			owner = Registry.getInstance().getModel(ownerId) as Table;
		}
		
		public function get rawType():String
		{
			if(this.type == null)
				return 'string';
			
			return this.type.split(/\(.*\)/).shift() as String;
		}
		
		public function get typeLength():String
		{
			if(this.type == null)
				return null;
			
			var _typeLength:Array = this.type.match(/(?<=\().*(?=\))/);
			
			if(_typeLength == null)
				return null;
			
			return _typeLength[0];
			
		}
		
	}
}