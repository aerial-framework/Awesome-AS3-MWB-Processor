package com.mysql.workbench.model.base
{
	import com.mysql.workbench.model.Registry;
	
	//Abstract Class
	public class Base
	{
		protected var xml:XML;
		
		public function Base(_xml:XML)
		{
			xml = _xml;
			Registry.getInstance().setModel(xml.@id, this);
		}
		

	}
}