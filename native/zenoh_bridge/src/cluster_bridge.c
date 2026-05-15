#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "zenoh.h"
#include "dart_api_dl.h"

static z_owned_session_t    g_session;
static z_owned_subscriber_t g_subscriber;
static Dart_Port            g_dart_port   = 0;
static int                  g_initialized = 0;

intptr_t cluster_bridge_init_dart_api(void *data) {
    return Dart_InitializeApiDL(data);
}

static void on_sample(z_loaned_sample_t *sample, void *arg) {
    if (g_dart_port == 0) return;

    const z_loaned_bytes_t *payload = z_sample_payload(sample);

    // Use reader API — works across all zenoh-c 1.x versions
    size_t len = z_bytes_len(payload);
    if (len == 0) return;

    uint8_t *buf = (uint8_t *)malloc(len);
    if (buf == NULL) return;

    z_bytes_reader_t reader = z_bytes_get_reader(payload);
    size_t read = z_bytes_reader_read(&reader, buf, len);

    if (read == len) {
        Dart_CObject msg;
        msg.type                       = Dart_CObject_kTypedData;
        msg.value.as_typed_data.type   = Dart_TypedData_kUint8;
        msg.value.as_typed_data.length = (intptr_t)len;
        msg.value.as_typed_data.values = buf;
        Dart_PostCObject_DL(g_dart_port, &msg);
    }

    free(buf);
}

static void on_drop(void *arg) {}

int cluster_bridge_start(
    const char *locator,
    const char *key_expr,
    Dart_Port   port
) {
    g_dart_port = port;

    z_owned_config_t config;
    z_config_default(&config);

    if (locator != NULL && strlen(locator) > 0) {
        char endpoints_json[256];
        snprintf(endpoints_json, sizeof(endpoints_json), "[\"%s\"]", locator);
        zc_config_insert_json5(z_loan_mut(config), "connect/endpoints", endpoints_json);
        zc_config_insert_json5(z_loan_mut(config), "scouting/multicast/enabled", "false");
        fprintf(stdout, "[bridge] connecting to %s\n", locator);
        fflush(stdout);
    }

    z_open_options_t open_opts;
    z_open_options_default(&open_opts);
    if (z_open(&g_session, z_move(config), &open_opts) != 0) {
        fprintf(stderr, "[bridge] z_open failed\n");
        return -2;
    }

    z_owned_keyexpr_t ke;
    if (z_keyexpr_from_str(&ke, key_expr) != 0) {
        fprintf(stderr, "[bridge] bad key expr\n");
        z_session_drop(z_move(g_session));
        return -3;
    }

    z_owned_closure_sample_t closure;
    z_closure_sample(&closure, on_sample, on_drop, NULL);

    z_subscriber_options_t sub_opts;
    z_subscriber_options_default(&sub_opts);

    int rc = z_declare_subscriber(
        z_session_loan(&g_session),
        &g_subscriber,
        z_keyexpr_loan(&ke),
        z_move(closure),
        &sub_opts
    );
    z_keyexpr_drop(z_move(ke));

    if (rc != 0) {
        fprintf(stderr, "[bridge] z_declare_subscriber failed: %d\n", rc);
        z_session_drop(z_move(g_session));
        return -4;
    }

    g_initialized = 1;
    fprintf(stdout, "[bridge] subscribed to '%s' via '%s'\n",
            key_expr, locator ? locator : "peer");
    fflush(stdout);
    return 0;
}

void cluster_bridge_stop(void) {
    if (!g_initialized) return;
    g_initialized = 0;
    g_dart_port   = 0;
    z_subscriber_drop(z_move(g_subscriber));
    z_session_drop(z_move(g_session));
    fprintf(stdout, "[bridge] stopped\n");
    fflush(stdout);
}
