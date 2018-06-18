include_relative_ifdef(CONFIG_COAP             coap/lib_coap.cmake)
include_relative_ifdef(CONFIG_LWM2M            lwm2m/lib_lwm2m.cmake)
include_relative_ifdef(CONFIG_SNTP             sntp/lib_sntp.cmake)
include_relative_ifdef(CONFIG_DNS_RESOLVER     dns/lib_dns.cmake)
include_relative_ifdef(CONFIG_MQTT_LIB         mqtt/lib_mqtt.cmake)
include_relative_ifdef(CONFIG_NET_APP          app/net_app.cmake)
include_relative_ifdef(CONFIG_NET_APP_SETTINGS config/net_config.cmake)
include_relative_ifdef(CONFIG_NET_SOCKETS      sockets/lib_sockets.cmake)
include_relative_ifdef(CONFIG_TLS_CREDENTIALS  tls_credentials/lib_tls_credentials.cmake)
include_relative_ifdef(CONFIG_WEBSOCKET        websocket/lib_websocket.cmake)

if(CONFIG_HTTP_PARSER_URL
    OR CONFIG_HTTP_PARSER
    OR CONFIG_HTTP)
  include(${CMAKE_CURRENT_LIST_DIR}/http/lib_http.cmake)
endif()

add_subdirectory_ifdef(CONFIG_OPENTHREAD_PLAT  ${CMAKE_CURRENT_LIST_DIR}/openthread)
