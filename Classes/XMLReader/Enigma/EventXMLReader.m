//
//  EventXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventXMLReader.h"

#import "../../Objects/Generic/Event.h"

@implementation EnigmaEventXMLReader

// Events are 'heavy'
#define MAX_EVENTS 100

+ (EnigmaEventXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	EnigmaEventXMLReader *xmlReader = [[EnigmaEventXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)sendErroneousObject
{
	Event *fakeObject = [[Event alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[self.target performSelectorOnMainThread: self.addObject withObject: fakeObject waitUntilDone: NO];
	[fakeObject release];
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <?xml-stylesheet type="text/xsl" href="/xml/serviceepg.xsl"?>
 <service_epg>
 <service>
 <reference>1:0:1:445d:453:1:c00000:0:0:0:</reference>
 <name>ProSieben</name>
 </service>
 <event id="0">
 <date>18.09.2008</date>
 <time>16:02</time>
 <duration>3385</duration>
 <description>Deine Chance! 3 Bewerber - 1 Job</description>
 <genre>n/a</genre>
 <genrecategory>00</genrecategory>
 <start>1221746555</start>
 <details>Starfotograf Jack 'Tin lichtet die deutsche Schowprominenz in seiner Fotoagentur in Hamburg ab. Dafür sucht er einen neuen Assistenten. Wer macht die besten Fotos: Sabrina (27), Thomas (28) oder Dominique (21)?</details>
 </event>
 </service_epg>
 */
- (void)parseFull
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedEventsCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/service_epg/service" error:nil];
	
	for (CXMLElement *resultElement in resultNodes) {
		if(++parsedEventsCounter >= MAX_EVENTS)
			break;

		// An service in the xml represents an event, so create an instance of it.
		Event *newEvent = [[Event alloc] init];

		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"start"])
			{
				[newEvent setBeginFromString: [currentChild stringValue]];
				continue;
			}
			else if([elementName isEqualToString:@"duration"])
			{
				[newEvent setEndFromDurationString: [currentChild stringValue]];
				continue;
			}
			else if([elementName isEqualToString:@"description"])
			{
				newEvent.title = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"details"])
			{
				newEvent.edescription = [currentChild stringValue];
				continue;
			}
		}
		
		[self.target performSelectorOnMainThread: self.addObject withObject: newEvent waitUntilDone: NO];
		[newEvent release];
	}
}

// XXX: incremental does not help very much - we'd only save a single element...

@end
