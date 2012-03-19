package com.mysql.workbench
{
	import mx.utils.StringUtil;

	public class FileWriter
	{
		public function FileWriter()
		{
		}
		
		private var _stream:String = "";
		private var _indentPosition:int = 0; //Keep track of new line indent position.
		private var _indentSize:int = 4; //Number of spaces to use for new line indentation.
		private var _cleanLine:Boolean = true;
		private var _lineEnding:String = "\n";
		
		public function get indentSize():int
		{
			return _indentSize;
		}
		
		public function set indentSize(value:int):void
		{
			if(_stream == "")
				_indentSize = value;
			else
				throw new Error("Can only change the 'indent' on an empty stream.");
		}
		
		private function  get currentIndent():String
		{
			return StringUtil.repeat(String.fromCharCode(32), indentSize * _indentPosition);
		}
		
		
		public function get stream():String
		{
			return _stream;
		}
		
		public function set stream(value:String):void
		{
			_stream = value;
			_cleanLine = false;
		}
		
		public function resetIndent():FileWriter
		{
			checkCleanLine();
			_stream = _stream.slice(0, -(_indentPosition * _indentSize));
			return this;
		}
		
		public function indentForward(n:uint=1):FileWriter
		{
			checkCleanLine();
			
			if(n == 0)
				return this;
			
			_stream += StringUtil.repeat(String.fromCharCode(32), indentSize * n);
			_indentPosition += n;
			return this;
		}
		
		public function indentBack(n:uint=1):FileWriter
		{
			checkCleanLine();
			
			if(n == 0)
				return this;
			else if(n > _indentPosition)
				throw new Error("Trying to back indent " + n.toString() + " times when only " + _indentPosition.toString() + " available.");
			
			_indentPosition -= n;
			_stream = _stream.slice(0, -(n * _indentSize));
			return this;
		}
		
		private function checkCleanLine():void
		{
			if(!_cleanLine)
				throw new Error("Operation only availalble on a clean new line.");
		}
		
		public function clear():FileWriter
		{
			_indentPosition = 0;
			_stream = "";
			_cleanLine = true;
			return this;
		}
		
		public function newLine(n:uint = 1):FileWriter
		{
			if(n == 0) 
				return this;
			
			_stream += StringUtil.repeat(this.lineEnding,n); //Add the number of line breaks;
			_stream += currentIndent; //Set the cursor at the current indent position;
			_cleanLine = true;
			return this;
		}
		
		public function add(text:String):FileWriter
		{
			this.stream += text;
			return this;
		}

		public function get lineEnding():String
		{
			return _lineEnding;
		}

		public function set lineEnding(value:String):void
		{
			_lineEnding = value;
		}		
	}
}