//
//  EDNLODLimitedTiledMapServiceLayer.h
//
//  Created by Nicholas Furness on 3/14/12.
//  Copyright (c) 2012 ESRI. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>

@interface AGSLODLimitedTiledLayer : AGSTiledServiceLayer
@property (nonatomic, retain, readonly) AGSTiledServiceLayer * wrappedTiledLayer;
@property (nonatomic, assign, readonly) NSInteger minLODLevel;
@property (nonatomic, assign, readonly) NSInteger maxLODLevel;

-(id)initWithBaseTiledMapServiceLayer:(AGSTiledServiceLayer *)baseLayer
						 fromLODLevel:(NSInteger)min 
						   toLODLevel:(NSInteger)max;

+(AGSLODLimitedTiledLayer *)lodLimitedTiledMapServiceLayer:(AGSTiledServiceLayer *)baseLayer
											  fromLODLevel:(NSInteger)min 
												toLODLevel:(NSInteger)max;

+(AGSLODLimitedTiledLayer *)lodLimitedTiledMapServiceLayerMatchingAppleLODs:(AGSTiledServiceLayer *)baseLayer;

+(AGSLODLimitedTiledLayer *)openStreetMapLayerFromLODLevel:(NSInteger)min 
												toLODLevel:(NSInteger)max;
+(AGSLODLimitedTiledLayer *)openStreetMapLayerMatchingAppleOSMLODS;
@end
