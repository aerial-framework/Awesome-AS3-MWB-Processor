package com.mysql.workbench.events
{
	import flash.events.Event;
	
	public class CodeGenEvent extends Event
	{
		public static const CREATED:String = "created";
		
		public function CodeGenEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public var fileType:String; // Model, Service
		public var filePackage:String;
		public var fileName:String;
		public var fileContent:String;
		
		public override function clone():Event
		{
			return new CodeGenEvent(this.type,this.bubbles,this.cancelable);
		}
	}
}