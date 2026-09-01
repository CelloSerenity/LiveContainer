//
//  main.m
//  LiveContainer
//
//  Created by Duy Tran on 30/8/26.
//
@import Foundation;

//void StikJITEnableJIT(int pid, NSURL* pairingFile, NSURL* ddiPath, NSString *script, BOOL forceScript);
@interface LiveProcessHandler : NSObject<NSExtensionRequestHandling>
+ (NSExtensionContext *)extensionContext;
+ (NSDictionary *)retrievedAppInfo;
@end

@interface StikJITWrapper : NSObject
+ (NSString *)enableJITWith:(int)pid pairingFile:(NSURL *)pairing ddiPath:(NSURL *)ddi scriptType:(NSInteger)scriptType scriptString:(NSString*)script;
@end

int StikJITHeadlessMain(void) {
    NSDictionary *appInfo = [NSClassFromString(@"LiveProcessHandler") retrievedAppInfo];
    NSURL *pairingFile = [NSURL URLByResolvingBookmarkData:appInfo[@"pairingBookmark"] options:0 relativeToURL:nil bookmarkDataIsStale:nil error:nil];
    NSURL *ddiPath = [NSURL URLByResolvingBookmarkData:appInfo[@"ddiBookmark"] options:0 relativeToURL:nil bookmarkDataIsStale:nil error:nil];
    NSString *script = nil;
    NSString *scriptBase64 = appInfo[@"script"];
    if (scriptBase64.length > 0) {
        NSData *scriptData = [[NSData alloc] initWithBase64EncodedString:scriptBase64 options:0];
        script = [[NSString alloc] initWithData:scriptData encoding:NSUTF8StringEncoding];
    }
    [pairingFile startAccessingSecurityScopedResource];
    [ddiPath startAccessingSecurityScopedResource];
    
    NSString *error = [StikJITWrapper enableJITWith:[appInfo[@"pid"] unsignedIntValue] pairingFile:pairingFile ddiPath:ddiPath scriptType:[appInfo[@"scriptType"] integerValue] scriptString:script];
    [pairingFile stopAccessingSecurityScopedResource];
    [ddiPath stopAccessingSecurityScopedResource];
    NSExtensionContext *context = [NSClassFromString(@"LiveProcessHandler") extensionContext];
    if (error.length > 0) {
        NSLog(@"Failed to enable JIT: %@", error);
        [context cancelRequestWithError:[NSError errorWithDomain:@"StikJIT" code:1 userInfo:@{NSLocalizedDescriptionKey: error}]];
    } else {
        [context completeRequestReturningItems:nil completionHandler:nil];
    }
    return 0;
}
