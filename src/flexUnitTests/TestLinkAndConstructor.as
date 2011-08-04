package flexUnitTests
{
	[NudgeConstructor(index="0", value="getLinkA", classDef="flexUnitTests.TestObject")]
	[NudgeConstructor(index="1", value="getLinkB", classDef="flexUnitTests.TestObject")]
	[Nudge(value="getInt", name="setInt", classDef="int")]
	
	public class TestLinkAndConstructor
	{
		private var _linkA:TestObject;
		private var _linkB:TestObject;
		private var _int:int;
		
		public function TestLinkAndConstructor( linkA:TestObject, linkB:TestObject )
		{
			this._linkA=linkA;
			this._linkB=linkB;
		}
	
		public function getLinkA():TestObject { return _linkA; }
		public function getLinkB():TestObject { return _linkB; }
		
		public function setInt( i:int ):void { this._int = i; }
		public function getInt():int { return _int; }
	}
}