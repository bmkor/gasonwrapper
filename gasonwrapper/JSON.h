//
//  JSON.h
//  gasonwrapper
//
//  Created by Benjamin on 19/5/2018.
//  Copyright © 2018 Benjamin. All rights reserved.
//

#ifndef JSON_h
#define JSON_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, JsonType){
    json_number,
    json_string,
    json_array,
    json_object,
    json_true,
    json_false,
    json_null
};

@interface JSONPrivate:NSObject
- (nullable NSString *) toString;
- (nullable NSNumber *) toNumber;
- (nullable NSNumber *) toBool;
- (nonnull NSString *) description;
- (nullable NSArray<JSONPrivate *> *) array;
- (JsonType) type;
- (nullable NSDictionary<NSString *, JSONPrivate *> *) object;
- (nullable JSONPrivate *) objectAtIndexedSubscript:(NSUInteger) index;
- (nullable JSONPrivate *) objectForKeyedSubscript:(nonnull NSString *) key;
- (nullable instancetype)initWithData:(NSData *_Nonnull)data error:(NSError * _Nullable * _Nullable)error;
@end

#endif /* JSON_h */
