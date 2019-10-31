//
//  Client.h
//  PJSIPCarthage
//
//  Created by Devansh Vyas on 09/08/19.
//  Copyright © 2019 Devansh Vyas. All rights reserved.
//

#include <stdio.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import "pjsua_app_common.h"
#import "pjsua_internal.h"

int registerSipUser(NSString* sipUser, NSString* sipDomain, NSString* password, NSString* proxy, int port);
void addSIPUserForCustomerSupport(char *sipUser, char* sipDomain, char* scheme, char* realm, char* username, int passwordType, char* passwd, char* proxy, int port);
void unregisterAccount(void);
void unregisterSupportAccount(int acc_id);
int sendCommand(char* to, char* command);
int isRegisteredUser(void);
int sendMessage(char* to, char* message, int account_id);
int makeCall(NSString* destUri, int acc_identity);
int makeVideoCall(NSString* destUri, int acc_identity);
void endAllCall(void);
void declineCall(int call_id, int code);
void answerCall(int call_identity);
void muteCall(BOOL status);
void onSpeaker(BOOL status);
int sendDTMS(NSString* digits);
void switchCamera(int call_id, BOOL is_front);
void pauseStream(int call_id, BOOL is_paused);
void setup_video_codec_params(void);
void registerThread(void);
void stop_all_vid_previews(void);
