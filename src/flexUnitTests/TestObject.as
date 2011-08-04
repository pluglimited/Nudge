package flexUnitTests
{
	[Nudge(value="getFloatProperty", name="floatProperty", classDef="Number")]
	[Nudge(value="getIntProperty", name="intProperty", classDef="int")]
	[Nudge(value="getBooleanProperty", name="booleanProperty", classDef="Boolean")]
	[Nudge(value="getStringProperty", name="stringProperty", classDef="String")]
	[Nudge(value="getNestedObject", name="nestedObject", classDef="flexUnitTests::TestObject")]
	
	public class TestObject
	{
		private var _stringProperty:String;
		private var _booleanProperty:Boolean;
		private var _intProperty:int;
		private var _floatProperty:Number;
		private var _nestedObject:TestObject;
		
		public function set getset( val:* ):void {}
		public function get getset():* {}
		
		
		public function floatProperty( value:Number ):void
		{
			this._floatProperty=value;
		}
		
		
		public function intProperty( value:int ):void
		{
			this._intProperty=value;
		}
		
		
		public function booleanProperty( value:Boolean ):void
		{
			this._booleanProperty=value;
		}
		
		
		public function stringProperty( value:String ):void
		{
			this._stringProperty=value;
		}
		
		
		public function nestedObject( value:TestObject ):void
		{
			this._nestedObject=value;
		}
		
		public function getFloatProperty():Number
		{
			return this._floatProperty;
		}
		
		public function getIntProperty():int
		{
			return this._intProperty;
		}
		
		public function getBooleanProperty():Boolean
		{
			return this._booleanProperty;
		}
		
		public function getStringProperty():String
		{
			return this._stringProperty;
		}
		
		public function getNestedObject():TestObject
		{
			return this._nestedObject;
		}
		
	}
}