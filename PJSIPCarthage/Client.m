
//
//  CLient.m
//  URC
//  Version 1.3
//
//  Created by Devansh Vyas on 09/08/19.
//  Copyright © 2019 Devansh Vyas. All rights reserved.
//


/**
 * START OF SIP CLIENT WRAPPER -----------------------------------------------------------------------------
 */



/**
 * Headers required for client to communicate with PJSIP
 */

#include "Client.h"
#include <PJSIPCarthage/pjsua-lib/pjsua.h>
#include <PJSIPCarthage/pjmedia_audiodev.h>
#include <PJSIPCarthage/pjmedia.h>

static NSString *const kUpdateDeviceTokenToServer = @"UpdateDeviceTokenToServer";
/**
 * Define this file to use with other classes
 */
#define THIS_FILE "Client.c"
#define on_pager_status_change "on_pager_status"
#define on_incoming_call_change  "on_incoming_call"
#define on_call_media_state_change  "on_call_media_state"
#define on_trasport_call_State_change  "on_trasport_call_State"
#define onCallTsxState_change  "onCallTsxState"
#define onSdpCreated_change  "onSdpCreated"
#define on_ip_change_progress_change  "on_ip_change_progress"
#define on_nat_change  "on_nat"
#define on_call_state_change  "on_call_state"
#define on_reg_status_change  "on_reg_status"


typedef struct systest_t
{
    pjsua_config        ua_cfg;
    pjsua_media_config        media_cfg;
    pjmedia_aud_dev_index   rec_id;
    pjmedia_aud_dev_index   play_id;
} systest_t;

/* Ringtones            US           UK  */
#define RINGBACK_FREQ1        440        /* 400 */
#define RINGBACK_FREQ2        480        /* 450 */
#define RINGBACK_ON        2000    /* 400 */
#define RINGBACK_OFF        4000    /* 200 */
#define RINGBACK_CNT        1        /* 2   */
#define RINGBACK_INTERVAL   4000    /* 2000 */

#define RING_FREQ1        800
#define RING_FREQ2        640
#define RING_ON            200
#define RING_OFF        100
#define RING_CNT        3
#define RING_INTERVAL        3000

#define current_acc    pjsua_acc_get_default()

#ifdef STEREO_DEMO
static void stereo_demo();
#endif

#ifdef USE_GUI
pj_bool_t showNotification(pjsua_call_id call_id);
#endif

/**
 *  Global Variables and Static Variables
 */
static pjsua_acc_id acc_id;
const size_t MAX_SIP_ID_LENGTH = 50;
const size_t MAX_SIP_REG_URI_LENGTH = 50;

// Enable/disable UA audio and video calls (should be always True if possible)
bool current_call_has_video = false;
bool call_is_active = false;
pjmedia_dir current_call_video_dir = PJMEDIA_DIR_NONE;          //SDP a=inactive
pjmedia_dir current_call_remote_video_dir = PJMEDIA_DIR_NONE;   //SDP a=inactive

/**
 * Display error and exit application
 *
 * @param title     The error message.
 * @param status    The error status code.
 */
static void error_exit(const char *title, pj_status_t status);


/**
 * Notify application when registration status has changed.
 * Application may then query the account info to get the
 * registration details.
 *
 * @param acc_id        The account ID.
 */
static void on_reg_state(pjsua_acc_id acc_id);


/**
 * This is the alternative version of the \a on_pager() callback with
 * \a pjsip_rx_data argument.
 *
 * @param call_id        Containts the ID of the call where the IM was
 *                sent, or PJSUA_INVALID_ID if the IM was sent
 *                outside call context.
 * @param from        URI of the sender.
 * @param to        URI of the destination message.
 * @param contact        The Contact URI of the sender, if present.
 * @param mime_type        MIME type of the message.
 * @param body        The message content.
 * @param rdata        The incoming MESSAGE request.
 * @param acc_id        Account ID most suitable for this message.
 */
static void on_pager2(pjsua_call_id call_id, const pj_str_t *from,
                      const pj_str_t *to, const pj_str_t *contact,
                      const pj_str_t *mime_type, const pj_str_t *body,
                      pjsip_rx_data *rdata, pjsua_acc_id acc_id);



/**
 * Notify application about the delivery status of outgoing pager
 * request. See also on_pager_status2() callback for the version with
 * \a pjsip_rx_data in the argument list.
 *
 * @param call_id        Containts the ID of the call where the IM was
 *                sent, or PJSUA_INVALID_ID if the IM was sent
 *                outside call context.
 * @param to        Destination URI.
 * @param body        Message body.
 * @param user_data        Arbitrary data that was specified when sending
 *                IM message.
 * @param status        Delivery status.
 * @param reason        Delivery status reason.
 */
static void on_pager_status(pjsua_call_id call_id,
                            const pj_str_t *to,
                            const pj_str_t *body,
                            void *user_data,
                            pjsip_status_code status,
                            const pj_str_t *reason);



static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_call_media_state(pjsua_call_id call_id);
static void on_call_rx_offer(pjsua_call_id call_id, const pjmedia_sdp_session *offer, void *reserved, pjsip_status_code *code, pjsua_call_setting *opt);
static void on_trasport_call_State(pjsip_transport *transport, pjsip_transport_state state, const pjsip_transport_state_info *info);
static void onCallTsxState(pjsua_call_id callId, pjsip_transaction *tsx, pjsip_event *event);
static void onSdpCreated(pjsua_call_id callId, pjmedia_sdp_session *sdp, pj_pool_t *pool, const pjmedia_sdp_session *remote);
static void on_ip_change_progress(pjsua_ip_change_op op, pj_status_t status, const pjsua_ip_change_op_info *info);
static void on_nat(const pj_stun_nat_detect_result *result);
static void on_dtmf(pjsua_call_id call_id, int code);

static bool is_video_possible(pjsua_call_id call_id);
static pj_status_t search_first_active_call(pjsua_call_id* pcall_id);
static bool is_audio_active(pjsua_call_id call_id);
static bool is_video_active(pjsua_call_id call_id);
static bool is_remote_video_active(pjsua_call_id call_id);
void setup_video_codec_params(void);
static void stop_all_vid_previews();
static pj_status_t set_video_stream(pjsua_call_id call_id, pjsua_call_vid_strm_op op, pjmedia_dir dir);

typedef struct _ringtone_port_info {
    int ring_on;
    int ring_slot;
    pjmedia_port *ring_port;
    pj_pool_t *pool;
} ringtone_port_info_t;

/** Function takes user credentials to login registered user
 * @param sipUser       SIP User to register
 * @param sipDomain     SIP Domain/Server
 * @param scheme        (e.g. "digest")
 * @param realm         Use "*" to make a credential that can be used to authenticate against any challenges.
 * @param username      User name for example sip_user@domain_name
 * @param passwordType  Type of password (0 for plaintext passwd)
 * @param passwd        Password of the SIP User
 * @param proxy         Specify the URL of outbound proxies to visit for all outgoing requests.
 *                      The outbound proxies will be used for all accounts, and it will
 *                      be used to build the route set for outgoing requests. The final
 *                      route set for outgoing requests will consists of the outbound proxies
 *                      and the proxy configured in the account.
 * @param port          Port on which your applciation will use for SIP communication
 *
 * @return When successful, returns 0.
 */
int registerSipUser(NSString* sipUser, NSString* sipDomain, NSString* scheme, NSString* realm, NSString* username, int passwordType, NSString* passwd, NSString* proxy, int port, int maxCalls)
{
    pj_status_t status;
    
    // Create pjsua first
    status = pjsua_create();
    if (status != PJ_SUCCESS) error_exit("Error in pjsua_create()", status);
    // Init pjsua
    {
        // Init the config structure
        pjsua_config        cfg;
        pjsua_config_default (&cfg);
        
        cfg.max_calls = maxCalls;
        cfg.cb.on_reg_state = &on_reg_state;
        cfg.cb.on_pager2 = &on_pager2;
        cfg.cb.on_pager_status = &on_pager_status;
        cfg.cb.on_incoming_call = &on_incoming_call;
        cfg.cb.on_call_media_state = &on_call_media_state;
        cfg.cb.on_call_state = &on_call_state;
        cfg.cb.on_transport_state = &on_trasport_call_State;
        cfg.cb.on_call_rx_offer = &on_call_rx_offer;
        cfg.cb.on_call_tsx_state = &onCallTsxState;
        cfg.cb.on_call_sdp_created = &onSdpCreated;
        cfg.cb.on_nat_detect = &on_nat;
        cfg.cb.on_dtmf_digit = &on_dtmf;
        //Media Config
        pjsua_media_config_default(&app_config.media_cfg);
        
        //app_config.media_cfg.enable_ice = PJ_TRUE;
        // app_config.media_cfg.snd_auto_close_time = 1;
        //        app_config.media_cfg.enable_turn = 1;
        //        app_config.media_cfg.turn_server = pj_str("40.143.136.38:5060");
        //        app_config.media_cfg.turn_auth_cred.data.static_cred.username = pj_str("1252");
        //        app_config.media_cfg.turn_auth_cred.data.static_cred.data = pj_str("e2360751bd");
        
        
        //        app_config.media_cfg.ice_no_rtcp = PJ_TRUE;
        //        app_config.media_cfg.ice_always_update = PJ_FALSE;
        //        app_config.media_cfg.ice_max_host_cands = 12;
        
        // app_config.media_cfg.clock_rate = PJSUA_DEFAULT_CLOCK_RATE;
        // app_config.media_cfg.snd_clock_rate = 0;
        // app_config.media_cfg.no_vad = PJ_TRUE;
        
        
        //Init the logging config structure
        pjsua_logging_config log_cfg;
        pjsua_logging_config_default(&log_cfg);
        log_cfg.console_level = 4;
        
        // Init PJ Media
        pjsua_media_config me_cfg;
        pjsua_media_config_default(&me_cfg);
        
        // Init the pjsua
        status = pjsua_init(&cfg, &log_cfg, &me_cfg);
        
        
        if (status != PJ_SUCCESS)
            error_exit("Error in pjsua_init()", status);
        // If outbound proxy is required.
        if (proxy) {
            app_config.cfg.outbound_proxy_cnt = 1;
            const char *proxyChar = [proxy UTF8String];
            app_config.cfg.outbound_proxy[0] = pj_str(proxyChar);
        }
        else
        {
            app_config.cfg.outbound_proxy_cnt = 0;
            app_config.cfg.outbound_proxy[0] = pj_str("");
        }
    }
    
    /* iOS version above iOS 4 do not support UDP in bakground. */
    // Add UDP transport.
        {
            // Init transport config structure
            pjsua_transport_config udp_cfg;
            pjsua_transport_config_default(&udp_cfg);
            udp_cfg.port = port;
    
            // Add UDP transport.
            status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &udp_cfg, NULL);
            if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
        }
    
    //Uncomment to enable TCP transport, but make sure TLS transport is commented.
    // Add TCP transport.
    //    {
    //        // Init transport config structure
    
    //        pjsua_transport_config cfg;
    //        pjsua_transport_config_default(&cfg);
    //        cfg.port = port;
    //
    //        // Add TCP transport.
    //        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &cfg, NULL);
    //        if (status != PJ_SUCCESS)
    //            error_exit("Error creating transport", status);
    //    }
    
    // Add TLS transport.
    //    {
    //        // Init transport config structure
    //        pjsua_transport_config cfg;
    //        pjsua_transport_config_default(&cfg);
    //        cfg.port = port;
    //
    //        // Add TCP transport.
    //        status = pjsua_transport_create(PJSIP_TRANSPORT_TLS, &cfg, NULL);
    //        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
    //    }
    
    
//    int success_in_binding_port = 0;
//
//    while (success_in_binding_port != 1) {
//
//        // Init transport config structure
//        pjsua_transport_config_default(&app_config.udp_cfg);
//        app_config.udp_cfg.port = port;
//
//
//        // Add TLS transport.
//        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &app_config.udp_cfg, NULL);
//        //        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
//        if (status != PJ_SUCCESS)
//        {
//            success_in_binding_port = 0;
//        }
//        else
//        {
//            success_in_binding_port = 1;
//        }
//
//        port--;
//    }
    
    // Initialization is done, now start pjsua
    //status = pjsua_start();
    if (status != PJ_SUCCESS) error_exit("Error starting pjsua", status);
    
    // Register the account on local sip server
    {
        pjsua_acc_config cfg;
        pjsua_acc_config_default(&cfg);
        
//        // Account cred info
//        cfg.cred_count = 1;
//        cfg.cred_info[0].scheme = pj_str("digest");
//        cfg.cred_info[0].realm = pj_str("*");
//        cfg.cred_info[0].username = pj_str(sipUser);
//        cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
//        cfg.cred_info[0].data = pj_str(password);
        
        //Normal Video Setup For Account
        cfg.vid_in_auto_show = PJ_TRUE;
        cfg.vid_out_auto_transmit = PJ_TRUE;
        cfg.vid_wnd_flags = PJMEDIA_VID_DEV_WND_BORDER | PJMEDIA_VID_DEV_WND_RESIZABLE;
        cfg.vid_cap_dev = PJMEDIA_VID_DEFAULT_CAPTURE_DEV;
        cfg.vid_rend_dev = PJMEDIA_VID_DEFAULT_RENDER_DEV;
        cfg.reg_retry_interval = 300;
        cfg.reg_first_retry_interval = 30;
        
        pj_str_t h264_codec_id = {"H264", 4};      //pj_str("H263-1998/96");
        pjsua_vid_codec_set_priority(&h264_codec_id, 2);
        
        setup_video_codec_params();
        
        char sipId[MAX_SIP_ID_LENGTH];
        const char *user = [sipUser UTF8String];
        const char *domain = [sipDomain UTF8String];
        sprintf(sipId, "sip:%s@%s", user, domain);
        cfg.id = pj_str(sipId);
        
        char regUri[MAX_SIP_REG_URI_LENGTH];
        sprintf(regUri, "sip:%s", domain);
        cfg.reg_uri = pj_str(regUri);
        
        // Add sip account credentials.
        cfg.cred_count = 1;
        const char *schemeChar = [scheme UTF8String];
        cfg.cred_info[0].scheme = pj_str(schemeChar);
        const char *realmChar = [realm UTF8String];
        cfg.cred_info[0].realm = pj_str(realmChar);
        const char *usernameChar = [username UTF8String];
        cfg.cred_info[0].username = pj_str(usernameChar);
        cfg.cred_info[0].data_type = passwordType;
        const char *passwdChar = [passwd UTF8String];
        cfg.cred_info[0].data = pj_str(passwdChar);
        
        
        status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
        if(status != PJ_SUCCESS)
            error_exit("Error adding account", status);
        app_config.acc_cfg[0]  = cfg;
    }
    status = pjsua_start();
    
    if (!pj_thread_is_registered()) {
        static pj_thread_desc   thread_desc;
        static pj_thread_t     *thread;
        pj_thread_register("background", thread_desc, &thread);
    }
    
    return 0;
}

int modifySipUser(char *sipUser, char* sipDomain, char* scheme, char* realm, char* username, int passwordType, char* passwd, char* proxy, int port){
    
    
    // Register the account on local sip server
    {
        pjsua_acc_config cfg;
        
        pjsua_acc_config_default(&cfg);
        
        char sipId[MAX_SIP_ID_LENGTH];
        sprintf(sipId, "sip:%s@%s", sipUser, sipDomain);
        cfg.id = pj_str(sipId);
        
        char regUri[MAX_SIP_REG_URI_LENGTH];
        sprintf(regUri, "sip:%s", sipDomain);
        cfg.reg_uri = pj_str(regUri);
        
        //        cfg.use_srtp = 1;
        
        // Add sip account credentials.
        cfg.cred_count = 1;
        cfg.cred_info[0].scheme = pj_str(scheme);
        cfg.cred_info[0].realm = pj_str(realm);
        cfg.cred_info[0].username = pj_str(username);
        cfg.cred_info[0].data_type = passwordType;
        cfg.cred_info[0].data = pj_str(passwd);
        //        cfg.publish_enabled = PJ_TRUE;
        if (acc_id == PJSUA_INVALID_ID)
        {
            return 1;
        }
        pj_status_t status = pjsua_acc_modify(acc_id, &cfg);
        //        status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
        if (status != PJ_SUCCESS) error_exit("Error adding account", status);
    }
    
    return 0;
}

/* Unregister SIP Account */
void unregisterAccount()
{
    pjsua_acc_id sipAccount = pjsua_acc_get_default();
    
    pjsua_acc_del(sipAccount);
    
    pjsua_destroy();
}

/* Unregister SIP Support User Account */
void unregisterSupportAccount(int acc_id)
{
    pjsua_acc_id sipAccountToLogout = acc_id;
    
    pjsua_acc_del(sipAccountToLogout);
    
    int acc_count = pjsua_acc_get_count();
    
    if (acc_count == 0) {
        pjsua_destroy();
    }
}

/* Callback called by the library upon receiving registration */
static void on_reg_state(pjsua_acc_id acc_id)
{
    pjsua_acc_info ci;
    
    pjsua_acc_get_info(acc_id, &ci);
    NSString *aid = [NSString stringWithFormat:@"%d",acc_id];
    if (ci.status == PJSIP_SC_OK) {
        pjsua_acc_set_online_status(acc_id, true);
    }
    else if (ci.status == PJSIP_SC_UNAUTHORIZED) {
    }
    else
    {
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithObjects:[NSArray arrayWithObjects:aid, nil] forKeys:[NSArray arrayWithObjects:@"account_id", nil]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"on_reg_status" object:NULL userInfo:dict];
    
}

pjsua_acc_info getAccountInfo(pjsua_acc_id acc_id)
{
    pjsua_acc_info ci;
    pjsua_acc_get_info(acc_id, &ci);
    return ci;
}

/* Callback called by library upon receiving command delivery status */
static void on_pager_status(pjsua_call_id call_id,
                            const pj_str_t *to,
                            const pj_str_t *body,
                            void *user_data,
                            pjsip_status_code status,
                            const pj_str_t *reason)
{
    
    const pj_str_t *status_code =  pjsip_get_status_text(status);
    
    printf ("%.*s", (int)status_code->slen, status_code->ptr);
    
    //    [SIPWrapper notifyUserOfInstantMessageStatus:[NSString stringWithFormat:@"%.*s", (int)status_code->slen, status_code->ptr]];
    
    if (status == PJSIP_SC_OK) {
        //  [SIPWrapper notifyUserOfCommandStatus:@"DELIVERED" forCommandID:call_id];
    }
    else if (status == PJSIP_SC_NOT_FOUND)
    {
        //[SIPWrapper notifyUserOfCommandStatus:@"CONTACT OFFLINE" forCommandID:call_id];
    }
    else if (status == PJSIP_SC_TEMPORARILY_UNAVAILABLE)
    {
        // [SIPWrapper notifyUserOfCommandStatus:@"TEMPORARILY UNAVAILABLE" forCommandID:call_id];
    }
    else if (status == PJSIP_SC_INTERNAL_SERVER_ERROR)
    {
        // [SIPWrapper notifyUserOfCommandStatus:@"INTERNAL SERVER ERROR" forCommandID:call_id];
    }
    else
    {
        // [SIPWrapper notifyUserOfCommandStatus:@"UNKNOWN ERROR OCCURED" forCommandID:call_id];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"on_pager_status" object:NULL userInfo:NULL];
}

/* Display error and exit application */
static void error_exit(const char *title, pj_status_t status)
{
    unsigned i;
    
    pjsua_perror(THIS_FILE, title, status);
    /* Close ring port */
    if (app_config.ring_port && app_config.ring_slot != PJSUA_INVALID_ID) {
        pjsua_conf_remove_port(app_config.ring_slot);
        app_config.ring_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(app_config.ring_port);
        app_config.ring_port = NULL;
    }
    
    /* Close tone generators */
    for (i=0; i<app_config.tone_count; ++i) {
        pjsua_conf_remove_port(app_config.tone_slots[i]);
    }
    
    if (app_config.pool) {
        pj_pool_release(app_config.pool);
        app_config.pool = NULL;
    }
    pjsua_destroy();
}

int isRegisteredUser(){
    pjsua_acc_info ci;
    pjsua_acc_get_info(acc_id, &ci);
    if (ci.status == PJSIP_SC_OK) {
        return 0;
    }
    return 1;
}


/* Send Command to Controller */
int sendCommand(char* to, char* command)
{
    pj_status_t status;
    
    pj_str_t to_buddy = pj_str(to);
    pj_str_t messageToSend = pj_str(command);
    
    
    status =  pjsua_im_send(acc_id, &to_buddy, NULL, &messageToSend, NULL, NULL);
    
    if (status != PJ_SUCCESS) error_exit("Error sending IM", status);
    
    return 0;
}

int sendDTMS(NSString* digits)
{
    pj_status_t status = 0;
    //Call identification.
    const char *cStr = [digits cStringUsingEncoding:NSASCIIStringEncoding]; // TODO: UTF8?
    
    pj_str_t result;
    pj_cstr(&result, cStr);
    pj_str_t pjDigits = result;
    if (current_call != -1)
    {
        status =  pjsua_call_dial_dtmf(current_call, &pjDigits);
    }
    if (status != PJ_SUCCESS) NSLog(@"Unable to call DTMF.");
    
    return 0;
}

/* Send Message to Customer Support Executive */
int sendMessage(char* to, char* message, int account_id)
{
    pj_status_t status;
    
    pj_str_t to_buddy = pj_str(to);
    pj_str_t messageToSend = pj_str(message);
    
    
    status =  pjsua_im_send(account_id, &to_buddy, NULL, &messageToSend, NULL, NULL);
    
    if (status != PJ_SUCCESS) error_exit("Error sending IM", status);
    
    return 0;
}


/* Callback called by library upon receiving command */
static void on_pager2(pjsua_call_id call_id, const pj_str_t *from,
                      const pj_str_t *to, const pj_str_t *contact,
                      const pj_str_t *mime_type, const pj_str_t *body,
                      pjsip_rx_data *rdata, pjsua_acc_id acc_id)
{
    PJ_LOG(3,(THIS_FILE, "MESSAGE from %.*s: %.*s (%.*s)", (int)from->slen, from->ptr, (int)body->slen, body->ptr, (int)mime_type->slen, mime_type->ptr));
    
    [[NSNotificationCenter defaultCenter] postNotificationName: @"on_pager_status" object:NULL];
    // [SIPWrapper notifyUserOfIncomingInstantMessageFromController:[NSString stringWithFormat:@"%s",from->ptr] andMessage:[NSString stringWithFormat:@"%s",body->ptr]];
}

/* Callback called by the library upon receiving incoming call */
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata)
{
    pjsua_call_info ci;
    
    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);
    current_call = call_id;
    
    pjsua_call_get_info(call_id, &ci);
    
    PJ_LOG(3,(THIS_FILE, "Incoming call from %.*s!!",
              (int)ci.remote_info.slen,
              ci.remote_info.ptr));
    BOOL isVideo;
    isVideo = ci.setting.vid_cnt;
    
    NSString *contactID = [NSString stringWithFormat:@"%s" , ci.remote_info.ptr];
    
    //----- video call method
//    int vid_idx;
//    pjsua_vid_win_id wid;
//    pj_status_t status;
//
//    vid_idx = pjsua_call_get_vid_stream_idx(call_id);
//    if (vid_idx >= 0) {
//        pjsua_call_info ci;
//
//        pjsua_call_get_info(call_id, &ci);
//        wid = ci.media[vid_idx].stream.vid.win_in;
//        printf("videoCall: wid:", wid);
//        printf("videoCall: idx:", vid_idx);
//    }
//
//    pjsua_vid_win_info info;
//    info.is_native = false;
//    info.show = true;
//
//    status = pjsua_vid_win_get_info(wid, &info);
//    printf("videoCall: status:", status);
    
//    pjsua_vid_win_set_show(wid, true);
    //-------
    
#ifdef USE_GUI
    if (!showNotification(call_id))
        return;
#endif
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc]init];
    [dictionary setObject:[NSString stringWithFormat:@"%d", call_id] forKey:@"callid"];
    [dictionary setObject:contactID forKey:@"caller"];
    [dictionary setObject:[NSNumber numberWithBool:isVideo] forKey:@"isVideo"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"on_incoming_call" object:NULL userInfo:dictionary];
}

static void convertTransactionState(pjsip_tsx_state_e state) {
    switch (state) {
        case PJSIP_TSX_STATE_PROCEEDING:
            NSLog(@"**\n SPCallTransactionStateProceeding");
        case PJSIP_TSX_STATE_DESTROYED:
            NSLog(@"SPCallTransactionStateDestroyed");
        case PJSIP_TSX_STATE_CONFIRMED:
            NSLog( @"SPCallTransactionStateConfirmed");
        case PJSIP_TSX_STATE_COMPLETED:
            NSLog( @"SPCallTransactionStateCompleted");
        case PJSIP_TSX_STATE_CALLING:
            NSLog( @"SPCallTransactionStateCalling");
        case PJSIP_TSX_STATE_TRYING:
            NSLog( @"SPCallTransactionStateTrying");
        case PJSIP_TSX_STATE_NULL:
            NSLog( @"SPCallTransactionStatePending");
        case PJSIP_TSX_STATE_TERMINATED:
            NSLog( @"SPCallTransactionStateTerminated");
        default:
            NSLog( @"SPCallTransactionStatePending");
    }
}

static void onCallTsxState(pjsua_call_id callId, pjsip_transaction *tsx, pjsip_event *event) {
    
    //convertTransactionState(tsx->state);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"onCallTsxState" object:NULL userInfo:NULL];
}

static void onSdpCreated(pjsua_call_id call_id, pjmedia_sdp_session *sdp, pj_pool_t *pool, const pjmedia_sdp_session *remote) {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"onSdpCreated" object:NULL userInfo:NULL];
}

static void on_ip_change_progress(pjsua_ip_change_op op,
                                  pj_status_t status,
                                  const pjsua_ip_change_op_info *info){
    PJ_LOG(3,(THIS_FILE, "chnage in IP state=%s", info));
    [[NSNotificationCenter defaultCenter]postNotificationName:@"on_ip_change_progress" object:NULL userInfo:NULL];
}

static void on_nat(const pj_stun_nat_detect_result *result) {
    
    if (result->status != PJ_SUCCESS) {
        pjsua_perror(THIS_FILE, "NAT detection failed", result->status);
    } else {
        PJ_LOG(3, (THIS_FILE, "NAT detected as %s", result->nat_type_name));
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"on_nat" object:NULL userInfo:NULL];
}

static void on_dtmf(pjsua_call_id call_id, int code){
    PJ_LOG(3, (THIS_FILE, "DTMF Dialed by %d", code));
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc]init];
    [dictionary setObject:[NSString stringWithFormat:@"%d", call_id] forKey:@"callId"];
    [dictionary setObject:[NSNumber numberWithInt:code] forKey:@"statusCode"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"on_dtmf" object:NULL userInfo:dictionary];
}

char* getstate(pjsip_status_code code){
    
    switch (code) {
        case PJSIP_SC_BUSY_HERE:
            return  "User is Busy";
            break;
        case PJSIP_SC_BUSY_EVERYWHERE:
            return  "User is Busy Everywhere";
            break;
        case PJSIP_SC_RINGING:
            return  "Ringing";
            break;
        case PJSIP_SC_TRYING:
            return "Trying";
            break;
        case PJSIP_SC_CALL_BEING_FORWARDED:
            return "CALL BEING FORWARDED";
            break;
        case PJSIP_SC_QUEUED:
            return "CALL Waiting";
            break;
        case PJSIP_SC_PROGRESS:
            return "CALL IN PROGRESS";
            break;
        case PJSIP_SC_OK:
            return "CALL OK";
            break;
        case PJSIP_SC_ACCEPTED:
            return "CALL ACCEPTED";
            break;
        case PJSIP_SC_USE_PROXY:
            return "CALL USING PROXY";
            break;
        case PJSIP_SC_MULTIPLE_CHOICES:
            return "CALL USING PROXY";
            break;
        case PJSIP_SC_MOVED_PERMANENTLY:
            return "CALL MOVED_PERMANENTLY";
            break;
        case PJSIP_SC_MOVED_TEMPORARILY:
            return "CALL MOVED_TEMPORARILY";
            break;
        case PJSIP_SC_ALTERNATIVE_SERVICE:
            return "CALL ALTERNATIVE_SERVICE";
            break;
        case PJSIP_SC_BAD_REQUEST:
            return "PJSIP_SC_BAD_REQUEST";
            break;
        case PJSIP_SC_UNAUTHORIZED:
            return "PJSIP_SC_UNAUTHORIZED";
            break;
        case PJSIP_SC_PAYMENT_REQUIRED:
            return "PJSIP_SC_PAYMENT_REQUIRED";
            break;
        case PJSIP_SC_FORBIDDEN:
            return "PJSIP_SC_FORBIDDEN";
            break;
        case PJSIP_SC_NOT_FOUND:
            return "PJSIP_SC_NOT_FOUND";
            break;
        case PJSIP_SC_METHOD_NOT_ALLOWED:
            return "PJSIP_SC_METHOD_NOT_ALLOWED";
            break;
        case PJSIP_SC_NOT_ACCEPTABLE:
            return "PJSIP_SC_NOT_ACCEPTABLE";
            break;
        case PJSIP_SC_PROXY_AUTHENTICATION_REQUIRED:
            return "PJSIP_SC_PROXY_AUTHENTICATION_REQUIRED";
            break;
        case PJSIP_SC_GONE:
            return "PJSIP_SC_GONE";
            break;
        case PJSIP_SC_REQUEST_ENTITY_TOO_LARGE:
            return "PJSIP_SC_REQUEST_ENTITY_TOO_LARGE";
            break;
        case PJSIP_SC_REQUEST_URI_TOO_LONG:
            return "PJSIP_SC_REQUEST_URI_TOO_LONG";
            break;
        case PJSIP_SC_UNSUPPORTED_MEDIA_TYPE:
            return "PJSIP_SC_UNSUPPORTED_MEDIA_TYPE";
            break;
        case PJSIP_SC_UNSUPPORTED_URI_SCHEME:
            return "PJSIP_SC_UNSUPPORTED_URI_SCHEME";
            break;
        case PJSIP_SC_BAD_EXTENSION:
            return "PJSIP_SC_BAD_EXTENSION";
            break;
        case PJSIP_SC_EXTENSION_REQUIRED:
            return "PJSIP_SC_EXTENSION_REQUIRED";
            break;
        case PJSIP_SC_SESSION_TIMER_TOO_SMALL:
            return "PJSIP_SC_SESSION_TIMER_TOO_SMALL";
            break;
        case PJSIP_SC_INTERVAL_TOO_BRIEF:
            return "PJSIP_SC_INTERVAL_TOO_BRIEF";
            break;
        case PJSIP_SC_TEMPORARILY_UNAVAILABLE:
            return "PJSIP_SC_TEMPORARILY_UNAVAILABLE";
            break;
        case PJSIP_SC_CALL_TSX_DOES_NOT_EXIST:
            return "PJSIP_SC_CALL_TSX_DOES_NOT_EXIST";
            break;
        case PJSIP_SC_LOOP_DETECTED:
            return "PJSIP_SC_LOOP_DETECTED";
            break;
        case PJSIP_SC_TOO_MANY_HOPS:
            return "PJSIP_SC_TOO_MANY_HOPS";
            break;
        case PJSIP_SC_ADDRESS_INCOMPLETE:
            return "PJSIP_SC_ADDRESS_INCOMPLETE";
            break;
        case PJSIP_AC_AMBIGUOUS:
            return "PJSIP_AC_AMBIGUOUS";
            break;
        case PJSIP_SC_REQUEST_TERMINATED:
            return "PJSIP_SC_REQUEST_TERMINATED";
            break;
        case PJSIP_SC_NOT_ACCEPTABLE_HERE:
            return "PJSIP_SC_NOT_ACCEPTABLE_HERE";
            break;
        case PJSIP_SC_BAD_EVENT:
            return "PJSIP_SC_BAD_EVENT";
            break;
        case PJSIP_SC_REQUEST_UPDATED:
            return "PJSIP_SC_REQUEST_UPDATED";
            break;
        case PJSIP_SC_REQUEST_PENDING:
            return "PJSIP_SC_REQUEST_PENDING";
            break;
        case PJSIP_SC_UNDECIPHERABLE:
            return "PJSIP_SC_UNDECIPHERABLE";
            break;
        case PJSIP_SC_INTERNAL_SERVER_ERROR:
            return "PJSIP_SC_INTERNAL_SERVER_ERROR";
            break;
        case PJSIP_SC_NOT_IMPLEMENTED:
            return "PJSIP_SC_NOT_IMPLEMENTED";
            break;
        case PJSIP_SC_BAD_GATEWAY:
            return "PJSIP_SC_BAD_GATEWAY";
            break;
        case PJSIP_SC_SERVICE_UNAVAILABLE:
            return "PJSIP_SC_SERVICE_UNAVAILABLE";
            break;
        case PJSIP_SC_SERVER_TIMEOUT:
            return "PJSIP_SC_SERVER_TIMEOUT";
            break;
        case PJSIP_SC_VERSION_NOT_SUPPORTED:
            return "PJSIP_SC_VERSION_NOT_SUPPORTED";
            break;
        case PJSIP_SC_MESSAGE_TOO_LARGE:
            return "PJSIP_SC_MESSAGE_TOO_LARGE";
            break;
        case PJSIP_SC_PRECONDITION_FAILURE:
            return "PJSIP_SC_PRECONDITION_FAILURE";
            break;
        case PJSIP_SC_NOT_ACCEPTABLE_ANYWHERE:
            return "PJSIP_SC_NOT_ACCEPTABLE_ANYWHERE";
            break;
        case PJSIP_SC_DOES_NOT_EXIST_ANYWHERE:
            return "PJSIP_SC_DOES_NOT_EXIST_ANYWHERE";
            break;
        case PJSIP_SC_TSX_TIMEOUT:
            return "PJSIP_SC_TSX_TIMEOUT";
            break;
        case PJSIP_SC__force_32bit:
            return "PJSIP_SC__force_32bit";
            break;
        default:
            break;
    }
    return "NULL State";
}

/* Callback called by the library when call's state has changed */
static void on_call_state(pjsua_call_id call_id, pjsip_event *e)
{
    PJ_UNUSED_ARG(e);
    
    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);
    
    if(callInfo.state == PJSIP_INV_STATE_CALLING)
    {
        NSLog(@"MyLogger: Calling...");
        // Nothing to do
    }
    else if(callInfo.state == PJSIP_INV_STATE_INCOMING)
    {
        // Case when this is the user agent that receives an INVITE from another user agent
//        NSString *fromString = to_NSString(&callInfo.remote_contact, NSUTF8StringEncoding);
//        NSString *fromUser = getUserFromSIPUri(fromString);
        NSLog(@"MyLogger: invite incoming...");
        current_call_has_video = is_video_possible(call_id);
//        [client receivedIncomingCall:call_id fromUser:fromUser];
    }
    else if(callInfo.state == PJSIP_INV_STATE_CONFIRMED)
    {
        NSLog(@"MyLogger: Call confirmed...");
        
        call_is_active = true;
        current_call_video_dir = PJMEDIA_DIR_ENCODING_DECODING;
        
        //Every call has only audio media available until is stablished. At this point, both endpoints must enable the video media for possible video media request during call.
//        setEnableVideoCall(true);
    }
    if(callInfo.state == PJSIP_INV_STATE_DISCONNECTED)
    {
        // If call has been disconnected from remote part then the video flag (and others) must be set to false
        current_call_has_video = false;
        call_is_active = false;
        current_call_remote_video_dir = PJMEDIA_DIR_NONE;
        current_call_video_dir = PJMEDIA_DIR_NONE;
        
    }
    
    
    
    PJ_LOG(3,(THIS_FILE, "Call %d state=%.*s", call_id,
              (int)callInfo.state_text.slen,
              callInfo.state_text.ptr));
    printf("Call States in Format code : %d State : %s \n",callInfo.last_status, getstate(callInfo.last_status));
    
    app_call_data *data;
    data = pjsua_call_get_user_data(call_id);
    
    current_call = call_id;
    int code;
    pj_str_t reason;
    pjsip_msg *msg;
    
    code = msg->line.status.code;
    reason = msg->line.status.reason;
    printf("StatusCode : %d description : %s \n",code, reason);
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc]init];
    [dictionary setObject:[NSString stringWithFormat:@"%s",callInfo.state_text.ptr] forKey:@"state"];
    [dictionary setObject:[NSString stringWithFormat:@"%s",callInfo.remote_info.ptr] forKey:@"contactId"];
    [dictionary setObject:[NSString stringWithFormat:@"%d", call_id] forKey:@"callId"];
    [dictionary setObject:[NSNumber numberWithInt:code] forKey:@"statusCode"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"on_call_state" object:NULL userInfo:dictionary];
}


static void on_trasport_call_State(pjsip_transport *transport, pjsip_transport_state state, const pjsip_transport_state_info *info)
{
    NSLog(@"Transport Changed");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"on_trasport_call_State" object:NULL userInfo:NULL];
}

/* Callback called by the library when call's media state has changed */
static void on_call_media_state(pjsua_call_id call_id)
{
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    pjsua_call_info call_info;
    
    pjsua_call_id current_call_id;
    pj_status_t status = search_first_active_call(&current_call_id);
    if(status != PJ_SUCCESS) {
        NSLog(@"Error searching first active call!");
        return;
    }
    
//    if (call_info.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
//        pjsua_conf_connect(call_info.conf_slot, 0);
//        pjsua_conf_connect(0, call_info.conf_slot);
//    }
 
    if(is_video_active(call_id) || is_remote_video_active(call_id))
    {
        // Setup the current h.263+ configuration
        setup_video_codec_params();
        
        // Start video stream
        set_video_stream(call_id, PJSUA_CALL_VID_STRM_START_TRANSMIT, PJMEDIA_DIR_NONE);
        
    }
    else
    {
        stop_all_vid_previews();
    }
    
    
    unsigned mi;
    pj_bool_t has_error = PJ_FALSE;
    
    pjsua_call_get_info(call_id, &call_info);
    
    
    for (mi=0; mi<call_info.media_cnt; ++mi) {
        printf("MyLogger: looping ");
//        on_call_generic_media_state(&call_info, mi, &has_error);
        
        switch (call_info.media[mi].type) {
            case PJMEDIA_TYPE_AUDIO:
                printf("MyLogger: case audio ");
//                on_call_audio_state(&call_info, mi, &has_error);
                break;
            case PJMEDIA_TYPE_VIDEO:
//                on_call_video_state(&call_info, mi, &has_error);
                NSLog(@"windows id : %d",ci.media[mi].stream.vid.win_in);
                NSLog(@"media id : %d",mi);
                printf("MyLogger: mediastatus", ci.media_status);
//                if (ci.media_status != PJSUA_CALL_MEDIA_ACTIVE)
//                    return;
                int i, last;
                pjsua_vid_win_id wid = ci.media[mi].stream.vid.win_in;
                i = (wid == PJSUA_INVALID_ID) ? 0 : wid;
                last = (wid == PJSUA_INVALID_ID) ? PJSUA_MAX_VID_WINS : wid+1;
                if(wid == PJSUA_INVALID_ID){
                    printf("MyLogger: displayWindow failed\n");
                }else{
                    printf("MyLogger: displayWindow success\n");
                }
                
                PJ_UNUSED_ARG(has_error);
                
                break;
            default:
                // Make gcc happy about enum not handled by switch/case
                printf("MyLogger: default case ");
                break;
        }
    }


    [[NSNotificationCenter defaultCenter] postNotificationName:@"on_call_media_state" object:NULL userInfo:NULL];
}

static void on_call_rx_offer(pjsua_call_id call_id, const pjmedia_sdp_session *offer, void *reserved, pjsip_status_code *code, pjsua_call_setting *opt)
{
    bool sdp_video_offer_accepted = false;
    
    // We will accept only video codec H263+
    int accepted_fmt_video_codec_id = 96; // Accepted video codec | 96 => H263-1998/90000
    
    //By default video media is disabled
    opt->vid_cnt = 0; //Video must be disabled until the offer received is accepted
    opt->aud_cnt = 1; //Audio is allways enabled
    
    pj_str_t video_media_type = {"video", 5};
    pj_str_t video_transport_type = {"RTP/AVP", 7};
    
    // At this point we received an sdp offer from the remote call endpoint
    // So, we have to check every media in the sdp and determine if we are able to run the media with the apropiate specs
    int i=0;
    for(i=0; i<offer->media_count; i++)
    {
        pjmedia_sdp_media *media = offer->media[i];
        
        // If media offer has video
        if((pj_strcmp(&media->desc.media, &video_media_type) == 0) && (media->desc.port > 0) && (pj_strcmp(&media->desc.transport, &video_transport_type) == 0))
        {
            //At this point we have to check if the video media specs in the offer are compatible with our specs
            int fmt_index=0;
            char fmt_string[150];
            
            for(fmt_index=0; fmt_index < media->desc.fmt_count; fmt_index++)
            {
                strncpy(fmt_string, media->desc.fmt[fmt_index].ptr, media->desc.fmt[fmt_index].slen);
                fmt_string[media->desc.fmt[fmt_index].slen] = '\0';
                
                // If our app supports h263+ codec and the app is active then we have to accept the sdp offer
                if([[NSString stringWithCString:fmt_string encoding:NSASCIIStringEncoding] intValue] == accepted_fmt_video_codec_id)
                {
                    NSLog(@"*** SDP video offer accepted ***");
                    sdp_video_offer_accepted = true; // Remote client is sending us a valid video media offer and app is active, so we accept it
                }
                
                if(sdp_video_offer_accepted)
                    break;
            }
            
            // If the video offer has been accepted then the next step is to get the video direction to setup the local machine state
            if(sdp_video_offer_accepted)
            {
                NSLog(@"*** SDP video offer accepted. Checking media direction. ***");
                
                //At this point we have to check the attributes assigned to the video media. Basicaly the media direction of the remote client
                int attr_index=0;
                char attr_name_string[255];
                char attr_value_string[255];
                bool video_direction_in_sdp = false; //There are cases when there are no video direction described in the SDP
                
                for(attr_index=0; (attr_index < media->attr_count) && (sdp_video_offer_accepted); attr_index++)
                {
                    strncpy(attr_name_string, media->attr[attr_index]->name.ptr, media->attr[attr_index]->name.slen);
                    attr_name_string[media->attr[attr_index]->name.slen] = '\0';
                    strncpy(attr_value_string, media->attr[attr_index]->value.ptr, media->attr[attr_index]->value.slen);
                    attr_value_string[media->attr[attr_index]->value.slen] = '\0';
                    
                    NSString *attr_name_nsstring = [NSString stringWithCString:attr_name_string encoding:NSASCIIStringEncoding];
                    
                    video_direction_in_sdp = true;
                    
                    if([attr_name_nsstring isEqualToString:@"sendonly"])
                    {
                        current_call_remote_video_dir = PJMEDIA_DIR_ENCODING_DECODING;
                        current_call_video_dir = PJMEDIA_DIR_ENCODING_DECODING;
                    }
                    else if([attr_name_nsstring isEqualToString:@"sendonly"])
                    {
                        // The requester only wants to send video
                        current_call_remote_video_dir = PJMEDIA_DIR_ENCODING;
                        current_call_video_dir = PJMEDIA_DIR_DECODING;
                    }
                    else if([attr_name_nsstring isEqualToString:@"recvonly"])
                    {
                        // The requester only wants to receive video
                        current_call_remote_video_dir = PJMEDIA_DIR_DECODING;
                        current_call_video_dir = PJMEDIA_DIR_ENCODING_DECODING;
                    }
                    else    video_direction_in_sdp = false;
                    
                    //NSLog(@"Attribute name (%s) | Value (%s)", attr_name_string, attr_value_string);
                }
            }
            else
            {
                // If video SDP offer is rejected then both video directions must be set to PJMEDIA_DIR_NONE
                current_call_remote_video_dir = PJMEDIA_DIR_NONE;
                current_call_video_dir = PJMEDIA_DIR_NONE;
                current_call_has_video = false;
            }
            
        }
    }
    
    // The video media will be accepted if sdp video offer was accepted
    opt->vid_cnt = sdp_video_offer_accepted ? 1 : 0;
    
    // Case when we are in video call mode and the remote user wants to switch to audio mode
    if((current_call_has_video) && (!sdp_video_offer_accepted))
    {
//        // Disable video mode
//        pjsua_call_setting_default(&call_setting);
//        call_setting.vid_cnt = 0; // 1 => hasVideo | 0 => hasNoVideo

        current_call_video_dir = PJMEDIA_DIR_NONE; /* PJMEDIA_DIR_ENCODING; */
        current_call_remote_video_dir = PJMEDIA_DIR_NONE; /* PJMEDIA_DIR_DECODING; */
        current_call_has_video = false;
    }
}

/* Make a sip call */
int makeCall(NSString* destUri, int acc_identity)
{
    
    // Append any required default headers
    pjsua_msg_data msg_data;
    pjsua_msg_data_init(&msg_data);
    pjsua_call_id cid;
    pj_status_t status;
    const char *uriChar = [destUri UTF8String];
    pj_str_t uri = pj_str(uriChar);
    //    pjsua_state state = pjsua_get_state();
    pjsua_acc_info info;
    status = pjsua_acc_get_info(acc_identity, &info);
    status = pjsua_call_make_call(acc_identity, &uri, 0, NULL,NULL, &cid);
    if (status != PJ_SUCCESS) {
        error_exit("Error making call", status);
    }
    return cid;
    
}

int makeVideoCall(NSString* destUri, int acc_identity)
{
    pjsua_call_setting opt;
    pjsua_call_setting_default(&opt);
    opt.aud_cnt = 1;
    opt.vid_cnt = 1;
    
    pjsua_msg_data msg_data;
    pjsua_msg_data_init(&msg_data);
    
    pjsua_call_id cid;
    pj_status_t status;
    const char *uriChar = [destUri UTF8String];
    pj_str_t uri = pj_str(uriChar);
    //    pjsua_state state = pjsua_get_state();
    pjsua_acc_info info;
    
    current_call_video_dir = PJMEDIA_DIR_ENCODING_DECODING;
    current_call_remote_video_dir = PJMEDIA_DIR_ENCODING_DECODING;
   
    status = pjsua_acc_get_info(acc_identity, &info);
    status = pjsua_call_make_call(acc_identity, &uri, &opt, NULL,NULL, &cid);
    
    if (status != PJ_SUCCESS) {
        error_exit("Error making call", status);
    }
    return cid;
    
}

/* End sip call */
void endCall()
{
    pjsua_call_hangup_all();
    
}

void declineCall(int call_id, int code){
    
    pjsua_msg_data msg_data;
    pjsua_msg_data_init(&msg_data);
    pjsua_call_hangup(call_id, code, NULL, &msg_data);
    
}

void answerCall(int call_identity)
{
    static pj_thread_desc a_thread_desc;
    static pj_thread_t *a_thread;
    pj_status_t status;
    if (!pj_thread_is_registered()) {
        pj_thread_register("ipjsua", a_thread_desc, &a_thread);
    }
//    pjsua_call_setting_default(&call_opt);
    call_opt.aud_cnt = 1;
    call_opt.vid_cnt = 1;
    call_opt.flag = PJSUA_CALL_INCLUDE_DISABLED_MEDIA;
    
    pjsua_vid_preview_param p_param;
    pjsua_vid_preview_param_default(&p_param);
    p_param.show = PJ_TRUE;
    
    status = pjsua_call_answer2(call_identity, &call_opt, 200, NULL, NULL);
    //    status = pjsua_call_answer(acc_identity,200, NULL, NULL);
    
    if (status != PJ_SUCCESS) error_exit("Error receiving call", status);
}

void muteCall(BOOL status)
{
    if (status) {
        pjsua_conf_adjust_rx_level (0,0);
        sendDTMS(@"1");
    }
    else{
        pjsua_conf_adjust_rx_level (0,1);
        sendDTMS(@"0");
    }
}

static bool is_video_possible(pjsua_call_id call_id)
{
    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);
    return callInfo.setting.vid_cnt>0 && callInfo.rem_vid_cnt>0;
}

static pj_status_t search_first_active_call(pjsua_call_id* pcall_id)
{
    pj_status_t result = PJ_FALSE;
    static const int MAX_CALLS = 20;
    pjsua_call_id call_ids[MAX_CALLS];
    unsigned int num_calls = MAX_CALLS;
    if (pjsua_enum_calls(call_ids, &num_calls) == PJ_SUCCESS)
    {
        for(int i=0; i < num_calls && result != PJ_SUCCESS; i++)
        {
            pjsua_call_id call = call_ids[i];
            if(pjsua_call_is_active(call))
            {
                *pcall_id = call;
                result = PJ_SUCCESS;
            }
        }
    }
    return result;
}

static bool is_audio_active(pjsua_call_id call_id)
{
    int mi = 0;
    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);
    for (mi=0; mi<callInfo.media_cnt; ++mi)
        switch (callInfo.media[mi].type)
    {
        case PJMEDIA_TYPE_AUDIO:
            if(callInfo.media[mi].status == PJSUA_CALL_MEDIA_ACTIVE)
                return true;
            break;
        default:
            /* Make gcc happy about enum not handled by switch/case */
            break;
    }
    
    return false;
}

static bool is_video_active(pjsua_call_id call_id)
{
    bool result=false;
    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);
    int index = pjsua_call_get_vid_stream_idx(call_id);
    if(index<callInfo.media_cnt) {
        result = (callInfo.media[index].status == PJSUA_CALL_MEDIA_ACTIVE);
    }
    NSLog(@"MyLogger: videoActive: %s", result ? "true" : "false");

    return result;
}

static bool is_remote_video_active(pjsua_call_id call_id)
{
    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);
    NSLog(@"MyLogger: remoteVideoActive: %s", (callInfo.rem_vid_cnt>0) ? "true" : "false");
    return (callInfo.rem_vid_cnt>0);
}

void setup_video_codec_params(void)
{
    //Set Video Codec Parameters before this starts transmitting
    
    pj_str_t h264_codec_id = {"H264", 4};      //pj_str("H263-1998/96");
    pjsua_vid_codec_set_priority(&h264_codec_id, 2);
    
    pjsua_codec_info vid_codec_ids[32];
    unsigned int vid_codec_count=PJ_ARRAY_SIZE(vid_codec_ids);
    
    pjsua_vid_enum_codecs(vid_codec_ids, &vid_codec_count);
    
    //For every codec
    for(int i=0;i<vid_codec_count; i++){
        
        pjmedia_vid_codec_param codec_param;
        
        //Get Configuration from codec in codecs list
        pj_status_t status_codec_get_params = pjsua_vid_codec_get_param(&(vid_codec_ids[i].codec_id), &codec_param);
        if(status_codec_get_params != PJ_SUCCESS)
        {
            NSLog(@"pjsua_vid_codec_get_param Failed!");
        }
        
        //MTU max value needs to be controlled to TEF router limits.
        codec_param.enc_mtu=1200;
        
        //Set Size
        codec_param.enc_fmt.det.vid.size.w = 640; //176; //352;
        codec_param.enc_fmt.det.vid.size.h = 480; //144; //288;
        
        codec_param.dec_fmt.det.vid.size.w = 640; //176; //352;
        codec_param.dec_fmt.det.vid.size.h = 480; //144; //288;
        
        codec_param.dec_fmtp.cnt = 1;
        codec_param.dec_fmtp.param[0].name = pj_str("profile-level-id"); //pj_str("CIF");     //pj_str("QCIF");    // 1st preference: 176 x 144 (QCIF)
        codec_param.dec_fmtp.param[0].val = pj_str("xxxx1f");//pj_str("2");        // 30000/(1.001*3) fps for QCIF
        
//        codec_param.dec_fmtp.param[1].name = pj_str("profile-level-id");
//        codec_param.dec_fmtp.param[1].val = pj_str("xxxx1f");
//        codec_param.dec_fmtp.param[1].name = pj_str("MaxBR");
//        codec_param.dec_fmtp.param[1].val = pj_str("5120");     //5120 // 2560 //1920 // = max_bps / 100
        
        /*        codec_param.dec_fmtp.param[2].name = pj_str("BPP");
         codec_param.dec_fmtp.param[2].val = pj_str("6554");     //65536*/
        
        // Set FPS.
        codec_param.enc_fmt.det.vid.fps.num   = 15000;
        codec_param.enc_fmt.det.vid.fps.denum = 1001;
        codec_param.dec_fmt.det.vid.fps.num   = 15000;
        codec_param.dec_fmt.det.vid.fps.denum = 1001;
        
        // Set Bandwidth.
        codec_param.enc_fmt.det.vid.avg_bps = 256000; //144000; //192000; //144000
        codec_param.enc_fmt.det.vid.max_bps = 512000; //256000; //192000
        codec_param.dec_fmt.det.vid.avg_bps = 256000; //144000; //192000; //144000
        codec_param.dec_fmt.det.vid.max_bps = 512000; //192000; //X256000; //192000
        
        // Set Configuration to codec in codecs list.
        pj_status_t status_codec_set_params = pjsua_vid_codec_set_param(&(vid_codec_ids[i].codec_id), &codec_param);
        
        NSLog(@"Codec name is %s", vid_codec_ids[i].desc.ptr);
        NSLog(@"MTU VALUE for codec #%d is %d", i, codec_param.enc_mtu);
        NSLog(@"FrameSize for codec #%d is w:%d h:%d", i, codec_param.enc_fmt.det.vid.size.w, codec_param.enc_fmt.det.vid.size.h);
        NSLog(@"FPS for codec #%d is %d/%d", i, codec_param.enc_fmt.det.vid.fps.num, codec_param.enc_fmt.det.vid.fps.denum);
        NSLog(@"BandWidth VALUE for codec #%d is avg:%d max:%d", i, codec_param.enc_fmt.det.vid.avg_bps, codec_param.enc_fmt.det.vid.max_bps);
        
        if(status_codec_set_params != PJ_SUCCESS)
        {
            NSLog(@"pjsua_vid_codec_set_param Failed!");
        }
    }
}

static void stop_all_vid_previews()
{
    static const int MAX_DEVS = 10;
    pjmedia_vid_dev_info info_devs[MAX_DEVS];
    unsigned int num_devs = MAX_DEVS;
    if(pjsua_vid_enum_devs(info_devs, &num_devs) == PJ_SUCCESS)
    {
        for(int i=0; i<num_devs; i++)
        {
            pjmedia_vid_dev_info dev_info = info_devs[i];
            {
                pjsua_vid_preview_param vid_preview_param;
                pjsua_vid_preview_param_default(&vid_preview_param);
                //pjsua_vid_preview_start(dev_info.id, &vid_preview_param);
                pjsua_vid_preview_stop(dev_info.id);
            }
        }
    }
}

static pj_status_t set_video_stream(pjsua_call_id call_id, pjsua_call_vid_strm_op op, pjmedia_dir dir)
{
    pjsua_call_vid_strm_op_param param;
    pjsua_call_vid_strm_op_param_default(&param);
    
    param.med_idx = pjsua_call_get_vid_stream_idx(call_id);
    param.dir = dir;
    param.cap_dev = PJMEDIA_VID_DEFAULT_CAPTURE_DEV;
    printf("MyLogger: In set video stream:");
    return pjsua_call_set_vid_strm(call_id, op, &param);
}
