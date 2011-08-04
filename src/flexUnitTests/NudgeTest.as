package flexUnitTests
{
	import com.pluglimited.nudge.Nudge;
	
	import flash.events.Event;
	import flash.utils.*;
	
	import flexunit.framework.Assert;
	import flexunit.framework.Test;
	import flexunit.framework.TestCase;
	
	import mx.collections.ArrayList;
	
	import org.flexunit.internals.namespaces.classInternal;
	import org.osmf.events.TimeEvent;
	
	public class NudgeTest extends TestCase
	{		
		import flexunit.framework.TestCase;
		import flash.utils.Timer;
		import flash.events.TimerEvent;
		
		private var db:Nudge;
		private var references:Vector.<Class> = new Vector.<Class>( TestObject );
		
		[Test]
		public function testGetEntryForKey():void
		{
			db = new Nudge();
			db.loadFromURL( "flexUnitTests/NudgeTest.xml" );
			db.addEventListener( Nudge.XMLPARSED, addAsync( verifyGetEntryForKey, 200 ) );
		}
		
		private function verifyGetEntryForKey( event:Event ):void
		{
			if ( db.getEntryForKey( "shouldFail" ) ) Assert.fail( "Should have returned null for absent key" );
			var test1:TestObject = db.getEntryForKey("test1");
			if ( test1==null ) Assert.fail("Test1 returned null");
			if ( !( test1 is TestObject ) ) Assert.fail("Test1 is incorrect type");
			
			if ( !TestObject(test1).getStringProperty()=="Testing Strings" ) Assert.fail("String property not set, got: "+TestObject(test1).getStringProperty() );
			if ( !TestObject(test1).getIntProperty()==12 ) Assert.fail("int property not set, got: "+TestObject(test1).getIntProperty() );
			if ( !TestObject(test1).getFloatProperty()==3.42 ) Assert.fail("double property not set, got: "+TestObject(test1).getFloatProperty() );
			
			if ( TestObject(test1).getNestedObject()==null ) Assert.fail("Nested Object is null");
			if ( !TestObject(test1).getNestedObject() is TestObject ) Assert.fail("Nested Object is not correct type");
	
			var nestedObject:TestObject = TestObject(test1).getNestedObject();

			if ( nestedObject.getStringProperty()!="Testing Nested Objects" ) Assert.fail("Nested Object Property not set, got: "+ nestedObject.getStringProperty());
			if ( db.getEntryForKey("test2")==null ) Assert.fail("Test2 null");
			
			var test2:TestObject = db.getEntryForKey("test2");
			if ( test2.getBooleanProperty() ) Assert.fail("Test 2 boolean property wrong value, got: "+test2.getBooleanProperty()); 
			
			var testingIdTag:String = db.getEntryForKey("testingIdTag");
			if ( !testingIdTag ) Assert.fail("TestingIdTag null" );
			if ( testingIdTag!="Testing id tag" ) Assert.fail( "TestingIdTag incorrect value, got: "+testingIdTag );
			
			var testString:Object = db.getEntryForKey("testString");
			if ( !testString is String ) Assert.fail("Test string object failed");
						
			var testInt:int = db.getEntryForKey("testInt");
			if ( !testInt is int ) Assert.fail("Test int failed");
			if ( testInt!=12 ) Assert.fail("Test int wrong value, got "+testInt);
			
			var test3:TestObject = db.getEntryForKey("test3");
			if (!test3 ) Assert.fail("test3 returned null");
			if ( !test3.getNestedObject()==test1 ) Assert.fail("Linked object failed");
			
			var testConstructor:TestLinkAndConstructor = db.getEntryForKey( "testConstructor" );
			if ( !testConstructor ) Assert.fail( "Test constructor null" );
			if ( !testConstructor.getLinkA() is TestObject ) Assert.fail( "Test constructor object A failed" );
			if ( !testConstructor.getLinkB() is TestObject ) Assert.fail( "Test constructor object B failed" );
			if ( !testConstructor.getLinkA().getBooleanProperty() ) Assert.fail( "Link A boolean property not set" );
			if ( testConstructor.getLinkA().getStringProperty() != "Testing id tag" ) Assert.fail( "Link A String property not set" );
			
			var testObjectWithNoParameters:TestObject = db.getEntryForKey( "testObjectWithNoParameters" );
			if ( !testObjectWithNoParameters ) Assert.fail( "testObjectWithNoParameters null.  Check object instantiation without property lists." );
			
		}
		
		[Test]
		public function testSerializeInt():void
		{
			var properties:Object = new Object();
			properties = 12;
			var xml:XML = Nudge.serialize( 12 );
			var result:int = Nudge.parseXMLAsObject( xml );
			if ( !result ) Assert.fail( "not an integer value" );
			if ( result!=12 ) Assert.fail( "incorrect value" );
		}
		
		[Test]
		public function testSerializeString():void
		{
			var xml:XML = Nudge.serialize( "test" );
			var result:String = Nudge.parseXMLAsObject( xml );
			if ( !result ) Assert.fail( "not a String" );
			if ( result!="test" ) Assert.fail( "wrong value, got: "+result );
		}
		
		[Test]
		public function testGetObjectsAsArray():void
		{
			db = new Nudge();
			db.loadFromURL( "flexUnitTests/NudgeTest.xml" );
			db.addEventListener( Nudge.XMLPARSED, addAsync( verifyGetObjectsAsArray, 200 ) );
		}
		
		[Test]
		public function testSerializeFromAnnotations():void
		{
			var test:TestObject = new TestObject();
			test.floatProperty(3.42);
			test.intProperty(5);
			test.stringProperty("nudge");
			test.booleanProperty(true);
			var xml:XML = Nudge.serialize( test );
			var result:TestObject = Nudge.parseXMLAsObject( xml );
			if ( !result ) Assert.fail( "null result!" );
			if ( result.getFloatProperty()!=3.42 ) Assert.fail( "float property incorrect, got: "+result.getFloatProperty() );
			if ( result.getIntProperty()!=5 ) Assert.fail( "int property incorrect, got: "+result.getIntProperty() );
			if ( result.getStringProperty()!="nudge") Assert.fail( "string property incorrect, got: "+result.getStringProperty() );
			if ( !result.getBooleanProperty() ) Assert.fail( "boolean property incorrect" );
		}
		
		[Test]
		public function testSerializeNestedClasses():void
		{
			var nested:TestObject = new TestObject();
			nested.stringProperty("nested");
			
			var test:TestObject = new TestObject();
			test.floatProperty(3.42);
			test.intProperty(5);
			test.stringProperty("nudge");
			test.booleanProperty(true);
			test.nestedObject( nested );
			
			var xml:XML = Nudge.serialize( test );
			var result:TestObject = Nudge.parseXMLAsObject( xml );
			if ( !result ) Assert.fail( "null result!" );
			if ( result.getFloatProperty() != 3.42 ) Assert.fail( "float property incorrect, got: "+result.getFloatProperty() );
			if ( result.getIntProperty() != 5 ) Assert.fail( "int property incorrect, got: "+result.getIntProperty() );
			if ( result.getStringProperty() != "nudge" ) Assert.fail( "string property incorrect, got: "+result.getStringProperty() );
			if ( !result.getBooleanProperty() ) Assert.fail( "boolean property incorrect, got false" );
			if ( !(result.getNestedObject() is TestObject) ) Assert.fail( "test object incorrect type" );
			if ( result.getNestedObject().getStringProperty() != "nested" ) Assert.fail( "nested string incorrect, got: "+result.getNestedObject().getStringProperty() );
		}
		
		[Test]
		public function testMXMLComponent():void
		{
			var test:TestComponent = new TestComponent();
			test.x = 100;
			test.y = 314;
			var xml:XML = Nudge.serialize( test );
			var result:TestComponent = Nudge.parseXMLAsObject( xml );
			if ( !result ) Assert.fail( "null result!" );
			if ( result.x != 100 ) Assert.fail( "x incorrect value, got: "+result.x );
			if ( result.y != 314 ) Assert.fail( "y incorrect value, got: "+result.y );
		}
		
		[Test]
		public function testSerializeConstructor():void
		{
			var linkA:TestObject = new TestObject();
			var linkB:TestObject = new TestObject();
			linkB.intProperty( 43 );
			if ( linkB.getIntProperty() != 43 ) Assert.fail( "LinkB int property not set" );
			var test:TestLinkAndConstructor = new TestLinkAndConstructor( linkA, linkB );
			var xml:XML = Nudge.serialize( test );
			var result:TestLinkAndConstructor = Nudge.parseXMLAsObject( xml );
			if ( !result ) Assert.fail( "result null" );
			if ( !result.getLinkA() ) Assert.fail( "Link A null" );
			if ( !result.getLinkB() ) Assert.fail( "Link B null" );
			if ( result.getLinkB().getIntProperty()!=linkB.getIntProperty() ) Assert.fail( "Link B int property not set" );
		}
		
		/**
		 * Test adding and retreiving objects into the database.
		 * */
		[Test]
		public function testAddingObjectsToDatabase():void
		{
			var obj:TestObject = new TestObject();
			var db:Nudge = new Nudge();
			db.addObjectToDatabase( obj, "test" );
			if ( db.getEntryForKey( "test" ) != obj ) Assert.fail( "storage in array failed" );
		}
		
		/**
		 * 
		 * Test objects with more complicated dependancies.
		 * Test adding objects sequentially to an xml database.
		 * This is acheived by adding all objects into the array, and then requesting an xml representation from Nudge.
		 * 
		 * */
		[Test]
		public function testSerializeComplexSystem():void
		{
			var db:Nudge = new Nudge();
			var obj1:TestObject = new TestObject();
			obj1.floatProperty( 3.14 );
			var obj2:TestObject = new TestObject();
			var link1:TestLinkAndConstructor = new TestLinkAndConstructor( obj1, obj2 );
			var obj3:TestObject = new TestObject();
			var link2:TestLinkAndConstructor = new TestLinkAndConstructor( obj2, obj3 );
			var link3:TestLinkAndConstructor = new TestLinkAndConstructor( obj3, obj1 );
			db.addObjectToDatabase( obj1, "obj1" );
			db.addObjectToDatabase( obj2, "obj2" );
			db.addObjectToDatabase( link1, "link1" );
			db.addObjectToDatabase( obj3, "obj3" );
			db.addObjectToDatabase( link2, "link2" );
			db.addObjectToDatabase( link3, "link3" );
			
			var xml:XML = db.getXML();
			
			var compressed:ByteArray = db.getCompressed();
			compressed.uncompress();
			var unCompressedXML:XML = XML( compressed.readUTF() );
			if ( unCompressedXML != xml ) Assert.fail( "Compression failed" );
			
			var base64:String = db.getBase64String();
			trace( base64 );
			
			if ( xml.child("reference").length() > 0 ) Assert.fail( "There should be no reference tags as children of the root element." );
			
			for each ( var node:XML in xml.children() ) {
				if ( node.child("constructor") && node.child("constructor").child("object").length() > 0 ) Assert.fail( "objects with constructors should all use references in this case." );
			}
			
			var result:Nudge = new Nudge();
			result.loadFromXML( xml );
			if ( !( result.getEntryForKey( "obj1" ) is TestObject ) ) Assert.fail( "result does not contain obj1" );
			if ( TestObject( result.getEntryForKey( "obj1" ) ).getFloatProperty()!=3.14 ) Assert.fail( "float property incorrect value" );
			if ( !( result.getEntryForKey( "obj2" ) is TestObject ) ) Assert.fail( "obj2 not a Test Object" );
			if ( !( result.getEntryForKey( "link1" ) is TestLinkAndConstructor ) ) Assert.fail( "link1 not TestLinkAndConstructor" );
			if ( !( result.getEntryForKey( "obj3" ) is TestObject ) ) Assert.fail( "obj3 not a Test Object" );
			if ( !( result.getEntryForKey( "link2" ) is TestLinkAndConstructor ) ) Assert.fail( "link2 not TestLinkAndConstructor" );
			if ( !( result.getEntryForKey( "link3" ) is TestLinkAndConstructor ) ) Assert.fail( "link3 not TestLinkAndConstructor" );
		}
		
		[Test]
		public function verifyGetObjectsAsArray( event:Event ):void
		{
			var test:ArrayList = db.getObjectsAsArray();
			if ( test.length!=10 ) Assert.fail("Array incorrect length");
		}
	}
}