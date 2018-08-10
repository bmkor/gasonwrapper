//
//  JSON.m
//  gasonwrapper
//
//  Created by Benjamin on 19/5/2018.
//  Copyright © 2018 Benjamin. All rights reserved.
//

#import "gason.hpp"
#import "JSON.h"
#import <Foundation/Foundation.h>
const int SHIFT_WIDTH = 4;

@interface JSONPrivate()
@property (nonatomic, assign) JsonAllocator  * _Nullable allocator;
@property (nonatomic, strong) NSMutableData *d;
@property (nonatomic, assign) char *endptr;
@property (nonatomic, assign) JsonValue value;
@end

@implementation JSONPrivate

- (nonnull instancetype) init{
    self = [super init];
    self.value = JsonValue();
    return self;
}

- (nullable instancetype)initWithData:(NSData *)data error:(NSError * _Nullable * _Nullable)error{
    self = [super init];
    if (self) {
        
        _d = [[NSMutableData alloc] initWithData:data];
        const char zeroByte = '\0';
        [_d appendBytes:&zeroByte length:1];
        
        _allocator = new JsonAllocator;
        _value = JsonValue();
        
        NSData *dcpy = [_d copy];
        
        int r = jsonParse((char *) dcpy.bytes, &_endptr, &_value, *(_allocator));
        
        if (r){
            const char *e = jsonStrError(r);
            NSString *errReason = [NSString stringWithCString:e encoding:NSUTF8StringEncoding];
            char *s = _endptr;
            char *source = (char *)_d.bytes;
            while (s != source && *s != '\n')
                --s;
            if (s != _endptr && s != source)
                ++s;
            
            int lineno = 0;
            for (char *it = s; it != source; --it) {
                if (*it == '\n') {
                    ++lineno;
                }
            }
            
            int column = (int)(_endptr - s);
            NSString *description = [NSString stringWithFormat:@"%@, lineno %d, column: %d", errReason, lineno + 1,column + 1];
            NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey:NSLocalizedString(errReason, nil), NSLocalizedDescriptionKey:NSLocalizedString(description, nil)};
            if (error != NULL){
                *error = [NSError errorWithDomain:[NSString stringWithFormat:@"JSONParsingError"] code:r userInfo:userInfo];
            }            
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithValue:(JsonValue) value{
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

- (void)dealloc
{
    if (_allocator) {
        delete _allocator;
    }
}

- (JsonType)type{
    switch (_value.getTag()) {
        case JSON_NULL:
            return json_null;
        case JSON_STRING:
            return json_string;
        case JSON_ARRAY:
            return json_array;
        case JSON_TRUE:
            return json_true;
        case JSON_FALSE:
            return json_false;
        case JSON_NUMBER:
            return json_number;
        case JSON_OBJECT:
            return json_object;
    }
}

- (nullable NSString *)toString{
    if (_value.getTag() == JSON_STRING){
        char *c = _value.toString();
        return c ? [NSString stringWithCString:c encoding:NSUTF8StringEncoding] : nil;
    }
    return nil;
}

- (nullable NSNumber *)toBool{
    JsonTag tag = _value.getTag();
    switch (tag) {
        case JSON_TRUE:
            return [NSNumber numberWithBool:true];
        case JSON_FALSE:
            return [NSNumber numberWithBool:false];
        default:
            return nil;
    }
}

- (nullable NSNumber *)toNumber{
    switch (_value.getTag()) {
        case JSON_NUMBER:
            return [NSNumber numberWithDouble:_value.toNumber()];
        default:
            return nil;
    }
}

- (nullable NSArray<JSONPrivate *> *)array{
    if (_value.getTag() == JSON_ARRAY) {
        
        NSMutableArray<JSONPrivate *> *a = [[NSMutableArray alloc] init];
        for (auto v = begin(_value); v != end({});) {
            [a addObject:[[JSONPrivate alloc] initWithValue:v.p->value]];
            ++v;
        }
        return [a copy];
    }
    return nil;
}

- (nullable NSDictionary<NSString *,JSONPrivate *> *)object{
    if (_value.getTag() == JSON_OBJECT) {
        NSMutableDictionary<NSString *, JSONPrivate *> *obj = [[NSMutableDictionary alloc] init];
        for (auto v = begin(_value); v != end({}); ++v) {
            char *k = v.p->key;
            if (!k) continue;
            NSString *key = [NSString stringWithCString:k encoding:NSUTF8StringEncoding];
            obj[key] = [[JSONPrivate alloc] initWithValue:v.p->value];
        }
        return [obj copy];
    }
    return nil;
}

- (nullable JSONPrivate *)objectForKeyedSubscript:(NSString *)key{
    if (_value.getTag() == JSON_OBJECT) {
        for (auto v = begin(_value); v != end({}); ) {
            char *k = v.p->key;
            const char *kk = key.UTF8String;
            if (kk && !strcmp(k, kk)) {
                return [[JSONPrivate alloc] initWithValue:v.p->value];
            }
            ++v;
        }
    }
    return nil;
}

- (JSONPrivate *)objectAtIndexedSubscript:(NSUInteger)index{
    if (_value.getTag() == JSON_ARRAY) {
        uint i = 0;
        for (auto v = begin(_value); v != end({}); ++v, ++i) {
            if (i == index) {
                return [[JSONPrivate alloc] initWithValue:v.p->value];
            }
        }
    }
    return nil;
}

- (nonnull NSString *)description
{
    return [self dumpValue:0];
}

-(nonnull NSString *) dumpValue:(int) indent {
    JsonValue o = _value;
    NSMutableString *ms = [[NSMutableString alloc] init];
    switch (o.getTag()) {
        case JSON_NUMBER:
            [ms appendString:[NSString stringWithFormat:@"%f",o.toNumber()]];
            break;
        case JSON_STRING:
            [ms appendString:[self dumpString:o.toString()]];
            break;
        case JSON_ARRAY:
            if (!o.toNode()){
                [ms appendString:@"[]"];
                break;
            }
            [ms appendString:@"[\n"];
            for (auto i: o){
                JSONPrivate *g = [[JSONPrivate alloc] initWithValue:i->value];
                [ms appendString:[@" " stringByPaddingToLength:indent + SHIFT_WIDTH withString:@" " startingAtIndex:0]];
                [ms appendString:[g dumpValue:indent + SHIFT_WIDTH]];
                [ms appendString:i->next ? @",\n" : @"\n"];
            }
            [ms appendString:[@" " stringByPaddingToLength:indent withString:@" " startingAtIndex:0]];
            [ms appendString:@"]"];
            break;
        case JSON_OBJECT:
            if (!o.toNode()){
                [ms appendString:@"{}"];
                break;
            }
            [ms appendString:@"{\n"];
            for (auto i: o) {
                if (i->key){
                    [ms appendString:[@" " stringByPaddingToLength:indent + SHIFT_WIDTH withString:@" " startingAtIndex:0]];
                    char *k = i->key;
                    if (k) {
                        NSString *key = [NSString stringWithCString:k encoding:NSUTF8StringEncoding];
                        if (key == nil){
                            key = @"";
                        }
                        [ms appendString:key];
                    }else{
                        [ms appendString:@""];
                    }
                    [ms appendString:@": "];
                }
                JSONPrivate *g = [[JSONPrivate alloc] initWithValue:i->value];
                [ms appendString:[g dumpValue:indent + SHIFT_WIDTH]];
                [ms appendString:i->next ? @",\n" : @"\n"];
            }
            [ms appendString:[@" " stringByPaddingToLength:indent withString:@" " startingAtIndex:0]];
            [ms appendString:@"}"];
            break;
        case JSON_NULL:
            [ms appendString:@"null"];
            break;
        case JSON_TRUE:
            [ms appendString:@"true"];
            break;
        case JSON_FALSE:
            [ms appendString:@"false"];
            break;
    }
    return [ms copy];
}

-(nonnull NSString *) dumpString:(const char *) s{
    if (s == nil || s == 0){
        return @"";
    }
    NSString *tmp = [NSString stringWithCString:s encoding:NSUTF8StringEncoding];
    if (tmp == nil){
        return @"";
    }
    NSMutableString *ms = [[NSMutableString alloc] initWithString:tmp];
    [ms replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [ms length])];
    //    [ms replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [ms length])];
    //    [ms replaceOccurrencesOfString:@"/" withString:@"\\/" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [ms length])];
    [ms replaceOccurrencesOfString:@"\b" withString:@"\\b" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [ms length])];
    [ms replaceOccurrencesOfString:@"\f" withString:@"\\f" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [ms length])];
    [ms replaceOccurrencesOfString:@"\r" withString:@"\\r" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [ms length])];
    [ms replaceOccurrencesOfString:@"\t" withString:@"\\t" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [ms length])];
    [ms replaceOccurrencesOfString:@"\n" withString:@"\\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [ms length])];
    return [NSString stringWithFormat:@"\"%@\"",ms];
}



@end

