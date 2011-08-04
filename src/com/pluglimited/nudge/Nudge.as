package com.pluglimited.nudge
{
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayList;
	import mx.utils.Base64Encoder;
	
	public class Nudge extends EventDispatcher
	{
		import flash.events.*;
		import flash.net.*;
		import flash.utils.*;
		import flash.system.*;
		import mx.utils.ObjectUtil;
		
		private var log:Vector.<Event> = new Vector.<Event>();
		
		private var database:Array = new Array();
		private var cache:Object = new Object();
		private var xmlRepresentation:XML = <root/>;
		
		public static var XMLPARSED:String="xmlParsed";
		private var uniqueId:int=0;
		
		
		public function loadFromXML( xml:XML ):void
		{
			parseXML( xml );
		}
		
		public function loadFromURL( dbURL:String ):void
		{
			var urlReq:URLRequest = new URLRequest( dbURL );
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, loadXML );
			urlLoader.addEventListener(Event.OPEN, logEvent );
			urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, logEvent );
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, logEvent );
			urlLoader.addEventListener(ProgressEvent.PROGRESS, logEvent );
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, logEvent );
			urlLoader.load( urlReq );
		}

		private function loadXML( event:Event=null ):void
		{
			logEvent( event );
			var db:XML=new XML( event.currentTarget.data );
			parseXML( db );
		}
		
		public function getEntryForKey( key:String ):*
		{
			return database[key];
		}
		
		public function getObjectsAsArray():ArrayList
		{
			var result:ArrayList = new ArrayList();
			for ( var key:String in database ) {
				result.addItem( database[key] );
			}
			return result;
		}
		
		public function addObjectToDatabase( object:*, id:String=null ):void
		{
			if ( id ) database[id] = object;
			else database.push( object );
		}
		
		/**
		 * 
		 * Returns a compressed ByteArray representation of all objects in the database.
		 * 
		 * 
		 * */
		
		public function getCompressed():ByteArray
		{
			var result:ByteArray = new ByteArray();
			result.writeUTF( getXML() );
			result.compress();
			return result;
		}
		
		/**
		 * 
		 * Returns a compressed escaped Base64 string representation of all objects in the database, hopefully suitable for URL encoding.  Untested!
		 * 
		 * 
		 * */
		
		public function getBase64String():String
		{
			var bytes:ByteArray = getCompressed();
			var encoder:Base64Encoder = new Base64Encoder();
			encoder.encodeBytes( bytes );
			return escape( encoder.toString() );
		}
		
		/**
		 * 
		 * ********************************************** FREEZE ************************************************
		 * 
		 * */
		
		/**
		 * 
		 * Returns an XML representation of all objects in the database.
		 * 
		 * Should only make one representation for each object, and use links for dependancies.
		 * 
		 * Should add nested objects to the cache as they are discovered.
		 * 
		 * */
		public function getXML():XML
		{
			xmlRepresentation = <root/>; // generate representaion each time.
			cache = new Object();
			uniqueId=0; // reset the unique id.  This is used to generate id tags for objects without id tags.
			
			var obj:XML;
			for ( var key:String in database ) {
				checkCacheForObject( database[key] );
			}
			return xmlRepresentation;		
		}
		
		/**
		 * 
		 * 
		 *  The serialize method should add the object to the cache.  This is so that all objects are added, even if they don't 
		 *  have an id tag.
		 * 
		 *  
		 * 
		 * */
		public function serialize( object:*, id:String=null):XML
		{
			var result:XML=<object/>;
			var key:String;
			if ( id ) key = id;  // if the id tag is specified use it
			else { // if the id tag is not specified
				key = getUniqueId(); // generate one
			}
			result.@id = key; // set the results id tag.
			cache[key] = object; // and add the object to the cache under the id.
			
			var className:String = describeType( object ).attribute("name").toString();
			result.@classDef=className;
			
			if ( ObjectUtil.isSimple( object ) ) result.@value=object;
			else {
				this.getConstructorListFromMetaData( object, result );
				this.getPropertiesListFromMetaData( object, result );
			}
			
			return result;
		}
		
		/**
		 * 
		 * Generates a unique key.
		 * 
		 * */
		private function getUniqueId():String
		{
			var key:String;
			while ( true ) {
				key = "auto"+uniqueId;
				if ( !cache[key] ) return key;
				uniqueId++;
			}
			return null;
		}
		
		/**
		 * 
		 * 
		 * 
		 * 
		 * Parses the constructor list from the objects meta data.
		 * 
		 * 
		 * 
		 * */
		private function getConstructorListFromMetaData( object:*, result:XML ):void
		{
			var constructor:XML, value:Object, link:XML;
			for each ( var meta:XML in describeType( object ).metadata ) {
				if ( meta.@name=="NudgeConstructor" ) {
					constructor = <constructor/>;

					for ( var i:int=0; i<meta.arg.length(); i++ ) {
						if ( meta.arg[i].@key=="index" ) constructor.@index = meta.arg[i].@value;
						else if ( meta.arg[i].@key=="value" ) {
							value = object[ meta.arg[i].@value ]();
							
							link = checkCacheForObject( value );
							if ( link ) constructor.appendChild( link );
							else constructor.appendChild( serialize( value ) );
						}
					}
					if ( constructor.@index && constructor.@classDef ) result.appendChild( constructor );
				}
			}
		}
		
		/**
		 * 
		 * 
		 * Parses the objects metadata and returns an object with property names, values and types to be serialized.
		 * FIXME: Type can be dynamically determined by reflection. 
		 * 
		 * value is the name of the get function
		 * name is the name of the set function
		 * classDef is the type of the return value
		 * 
		 * 
		 * */
		private function getPropertiesListFromMetaData( object:*, result:XML ):void
		{
			var property:XML, key:String, value:String, data:Object, link:XML;
			for each ( var meta:XML in describeType( object ).metadata ) {
				if ( meta.@name=="Nudge" ) {
					property = <property/>;
					for ( var i:int=0; i<3; i++ ) {
						key = meta.arg[i].@key;
						value = meta.arg[i].@value;
						if ( key=="value" ) {
							data = object[value]();
							if ( data ) {
								link = checkCacheForObject( value );
								if ( link ) {
									property = link;
									break;
								} else if ( ObjectUtil.isSimple( data ) ) property.@value = data.toString();
								else getPropertiesListFromMetaData( data, property );
							} else {
								property=null;
								break;	// don't try to serialize null properties!
							} 
						}
						else if ( key=="classDef" ) property.@classDef = value;
						else if ( key=="name" ) property.@name = value;
					}
					if ( property ) result.appendChild( property );
				}
			}
		}
		
		/**
		 * 
		 * Checks object cache for object.  
		 * 
		 * if an object is not found in the cache it is created as an <object/> and added to the xml representation.  
		 * A link is then returned to the object.
		 * 
		 * Returns a xml reference to the object if it has already been used.  Otherwise returns null.
		 * 
		 * */
		private function checkCacheForObject( object:Object ):XML
		{
			var xml:XML;
			var id:String;
			for ( var key:String in cache ) {
				if ( cache[key] === object ) {
					xml = <reference/>;
					xml.@value = key;
					return xml;
				}
			}
			id = checkDatabaseForObjectId( object );
			if ( id ) {
				xmlRepresentation.appendChild( this.serialize( object, checkDatabaseForObjectId( object ) ) ); // object is not yet in cache, so serialize it as an object.
				xml = <reference/>;
				xml.@value = id;
				return xml; // and return a link to the object
			}
			return null;
		}
		
		/**
		 * 
		 * Checks if an object is declared with an id tag somewhere in the database.
		 * 
		 * */
		private function checkDatabaseForObjectId( object:Object ):String
		{
			for ( var key:String in database ) {
				if ( database[key] === object ) {
					return key;	
				}
			}
			return null;
		}
		
		public function getLog():Vector.<Event>
		{
			return log;
		}
		
		private function logEvent( event:Event=null ):void
		{
			log.push( event );
		}
		
		/**
		 * 
		 * ********************************************** THAW ************************************************
		 * 
		 * */
		
		private function parseXML( root:XML ):void
		{
			var objects:XMLList=root.object;
			
			for ( var i:int=0; i<objects.length(); i++ ) {
				parseXMLAsObject( objects[i] );
			}
			dispatchEvent( new Event( Nudge.XMLPARSED, true ) );
		}
		
		/**
		 * 
		 * 
		 * */
		
		private function parseXMLAsObject( objectDefinition:XML ):*
		{
			var instance:Object, newClass:Class, properties:XMLList, value:Object;
			var className:String = objectDefinition.attribute("classDef");
			var objectRef:String = objectDefinition.reference;
			var id:String = objectDefinition.attribute("id");
			var constructor:XMLList = objectDefinition.constructor;
			
			if ( className && !objectRef )  {
				newClass = ApplicationDomain.currentDomain.getDefinition( className ) as Class;
				if ( constructor && constructor.length() > 0 ) {
					instance = this.parseConstructor( newClass, constructor );
				} else {
					instance = new newClass();
				}
				properties = objectDefinition.property;
				value = objectDefinition.attribute("value").toString();
				if ( properties && properties.length() > 0 ) giveProperties( properties, instance );
				else if ( value ) instance = newClass( value );
			} else if ( objectRef ) {
				instance = database[ objectRef ];
			}
			if ( instance && id ) {
				database[ id ] = instance;
			}
			return instance;
		}
		
		/**
		 * 
		 * 
		 * Parses the properties defined in the <constructor/> elements and puts them into the order of their index attributes.
		 * These are passed to the constructor.
		 * 
		 * If there are missing indexes, null will be passed to the constructor.
		 * 
		 * If there are multiple constructor tabs with the same index, only one will be passed to the constructor.
		 * 
		 * A minimum of 0 and maximum of 7 parameters can be passed to the constructor.
		 * 
		 * In each constructor tag, only the first child object will be parsed.
		 * 
		 * 
		 * */
		
		private function parseConstructor( newClass:Class, constructor:XMLList ):*
		{
			var args:Array = new Array();
			var object:XML;
			for each ( var xml:XML in constructor ) {
				if ( xml.object ) object = xml.object[0];
				else if ( xml.reference ) object = xml.reference[0];

				if ( object ) args[xml.@index] = this.parseXMLAsObject( object );
			}
			return callConstructor( newClass, args );
		}
		
		/**
		 * 
		 * 
		 * Parses the properties defined in the <constructor/> elements and puts them into the order of their index attributes.
		 * These are passed to the constructor.
		 * 
		 * If there are missing indexes, null will be passed to the constructor.
		 * 
		 * If there are multiple constructor tabs with the same index, only one will be passed to the constructor.
		 * 
		 * A minimum of 0 and maximum of 7 parameters can be passed to the constructor.
		 * 
		 * In each constructor tag, only the first child object will be parsed.
		 * 
		 * 
		 * 
		 * */
		
		private static function parseConstructor( newClass:Class, constructor:XMLList ):*
		{
			var args:Array = new Array();
			for each ( var xml:XML in constructor ) {
				if ( xml.object[0] ) args[xml.@index] = parseXMLAsObject( xml.object[0] );
			}
			return callConstructor( newClass, args );
		}
		
		private static function callConstructor( newClass:Class, args:Array ):*
		{
			var argLength:int = describeType( newClass ).factory.constructor.parameter.length();
			switch ( argLength ) {
				case 0: return new newClass();
				case 1: return new newClass( args[0] );
				case 2: return new newClass( args[0], args[1] );
				case 3: return new newClass( args[0], args[1], args[2] );
				case 4: return new newClass( args[0], args[1], args[2], args[3] );
				case 5: return new newClass( args[0], args[1], args[2], args[3], args[4] );
				case 6: return new newClass( args[0], args[1], args[2], args[3], args[4], args[5] );
				case 7: return new newClass( args[0], args[1], args[2], args[3], args[4], args[5], args[6] );
			}
			return null;
		}
		
		private function giveProperties( property:XMLList, instance:Object ):void
		{
			var method:String, value:Object, type:String, classType:Class;
			
			for ( var i:int=0; i<property.length(); i++ ) {
				method = property[i].attribute("name");
				type = property[i].attribute("classDef");
				classType = ApplicationDomain.currentDomain.getDefinition( type ) as Class;
				if ( type=="Boolean" ) {
					value = ( property[i].attribute("value").toString()=="true" ) ? true : false;
				} else {
					value = classType( parseXMLAsObject( property[i] ) );
				}
				if ( method && value ) {
					instance[method](value);
				}
			}
		}
		
		/**
		 * Will not serialise links / references.
		 * 
		 * */
		public static function serialize( object:*, id:String=null):XML
		{
			var result:XML=<object/>;
			if ( id ) result.@id = id;
			var className:String = describeType( object ).attribute("name").toString();
			result.@classDef=className;
			
			if ( ObjectUtil.isSimple( object ) ) result.@value=object;
			else {
				getConstructorListFromMetaData( object, result );
				getPropertiesListFromMetaData( object, result );
			}

			return result;
		}
		/**
		 * 
		 * 
		 * Parses the objects metadata and returns an object with property names, values and types to be serialized.
		 * FIXME: Split into smaller methods.
		 * FIXME: Type can be dynamically determined by reflection. 
		 * 
		 * value is the name of the get function
		 * name is the name of the set function
		 * classDef is the type of the return value
		 * 
		 * 
		 * */
		private static function getPropertiesListFromMetaData( object:*, result:XML ):void
		{
			var property:XML, key:String, value:String, data:Object;
			for each ( var meta:XML in describeType( object ).metadata ) {
				if ( meta.@name=="Nudge" ) {
					property = <property/>;
					for ( var i:int=0; i<3; i++ ) {
						key = meta.arg[i].@key;
						value = meta.arg[i].@value;
						if ( key=="value" ) {
							data = object[value]();
							if ( data ) {
								if ( ObjectUtil.isSimple( data ) ) property.@value = data.toString();
								else getPropertiesListFromMetaData( data, property );
							} else {
								property=null;
								break;	// don't try to serialize null properties!
							} 
						}
						else if ( key=="classDef" ) property.@classDef = value;
						else if ( key=="name" ) property.@name = value;
					}
					if ( property ) result.appendChild( property );
				}
			}
		}
		
		private static function getConstructorListFromMetaData( object:*, result:XML ):void
		{
			var constructor:XML, value:Object;
			for each ( var meta:XML in describeType( object ).metadata ) {
				if ( meta.@name=="NudgeConstructor" ) {
					constructor = <constructor/>;
					for ( var i:int=0; i<meta.arg.length(); i++ ) {
						if ( meta.arg[i].@key=="index" ) constructor.@index = meta.arg[i].@value;
						else if ( meta.arg[i].@key=="value" ) {
							value = object[ meta.arg[i].@value ]();
							constructor.appendChild( serialize( value ) );
						}
					}
					if ( constructor.@index && constructor.@classDef ) result.appendChild( constructor );
				}
			}
		}
		
		
		/**
		 * 
		 * 
		 * Fixes a bug in actionscript's XML handling where the "<" and ">" characters are escaped.
		 * 
		 * 
		 * */
		
		public static function fixXMLBug( xml:XML ):XML
		{
			var escapedGT:RegExp = /&gt;/g;
			var escapedLT:RegExp = /&lt;/g;
			var filtered:String = xml.toString().replace(escapedGT, ">");
			filtered = filtered.replace(escapedLT, "<");
			return XML( filtered );
		}
		
		public static function parseXMLAsObject( objectDefinition:XML ):*
		{
			var instance:Object, newClass:Class, properties:XMLList, value:String;
			var className:String = objectDefinition.@classDef;
			var constructor:XMLList = objectDefinition.constructor;
			
			if ( className )  {
				newClass = ApplicationDomain.currentDomain.getDefinition( className ) as Class;
				if ( constructor && constructor.length() > 0 ) {
					instance = parseConstructor( newClass, constructor );
				} else {
					instance = new newClass();
				}
				
				properties = objectDefinition.property;
				value = objectDefinition.@value.toString();
				if ( properties && properties.length() > 0 ) giveProperties( properties, instance );
				else if ( value ) instance = newClass( value ); 
				
				return instance;
			}
		}
		
		/**
		 * 
		 * TODO: Incorrect meta data can cause run time exceptions.  Catch errors.
		 * 
		 * */
		
		private static function giveProperties( property:XMLList, instance:Object ):void
		{
			var method:String, value:Object, type:String, classType:Class;
			
			for ( var i:int=0; i<property.length(); i++ ) {
				method = property[i].@name;
				type = property[i].@classDef;
				classType = ApplicationDomain.currentDomain.getDefinition( type ) as Class;
				value = classType( parseXMLAsObject( property[i] ) );
				
				if ( method && value ) instance[method](value);
			}
		}
	}
}