// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:micropack_core/config/micropack_config.dart';
import 'package:micropack_core/config/micropack_init.dart';
import 'package:micropack_core/utils/micropack_storage.dart';

import '../utils/micropack_utils.dart';
import 'package:dio/dio.dart';

enum Method { POST, GET, PUT, DELETE, PATCH }

class MicropackApiService {
  static Dio? _dio;

  Future<MicropackApiService> init() async {
    logSys('Api Service Initialized - ${MicropackConfig.baseUrl}');
    _dio = Dio(
      BaseOptions(
        baseUrl: MicropackConfig.baseUrl,
        headers: {'Content-Type': 'application/json'},
        connectTimeout: Duration(seconds: MicropackInit.requestTimeout),
        receiveTimeout: Duration(seconds: MicropackInit.requestTimeout),
        sendTimeout: Duration(seconds: MicropackInit.requestTimeout),
      ),
    );
    initInterceptors();
    return this;
  }

  static void initInterceptors() {
    _dio?.interceptors.add(
      InterceptorsWrapper(
        onRequest: (requestOptions, handler) {
          logSys(
            '[REQUEST_METHOD] : ${requestOptions.method}\n[URL] : ${requestOptions.baseUrl}\n[PATH] : ${requestOptions.path}'
            '\n[PARAMS_VALUES] : ${requestOptions.data}\n[QUERY_PARAMS_VALUES] : ${requestOptions.queryParameters}\n[HEADERS] : ${requestOptions.headers}',
          );
          return handler.next(requestOptions);
        },
        onResponse: (response, handler) {
          logSys(
            '[RESPONSE_STATUS_CODE] : ${response.statusCode}\n[RESPONSE_DATA] : ${jsonEncode(response.data)}\n',
          );
          return handler.next(response);
        },
        onError: (err, handler) {
          logSys('Error-> $err]');
          logSys('Error[${err.response?.statusCode}]');
          return handler.next(err);
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> getHeader({
    Map<String, dynamic>? headers,
    required bool isToken,
  }) async {
    final header = <String, dynamic>{'Content-Type': 'application/json'};

    // Jika headers tidak null, tambahkan semua headers yang ada ke header baru
    if (headers != null) {
      header.addAll(headers);
    }

    if (isToken) {
      var token = await MicropackStorage.read(key: MicropackInit.boxToken);
      header['Authorization'] = 'Bearer $token';
    }
    return header;
  }

  static Future<String> getGatewayKey(int unixtime) async {
    var result = '';
    if (MicropackInit.appFlavor == Flavor.production ||
        MicropackInit.appFlavor == Flavor.staging ||
        kReleaseMode) {
      result = await MicropackUtils.encryptHMAC(unixtime, MicropackInit.apiKey);
    } else {
      result = MicropackInit.apiDevKey;
    }
    return result;
  }

  static Future<dynamic> request({
    required String url,
    required Method method,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? parameters,
    FormData? formData,
    bool isToken = true,
    bool isCustomResponse = false,
  }) async {
    Response response;

    final params = parameters ?? <String, dynamic>{};

    final header = await getHeader(headers: headers, isToken: isToken);

    try {
      final unixTime = DateTime.now().millisecondsSinceEpoch;
      // Add gatewayKey to header if needed
      if (MicropackInit.appFlavor == Flavor.production) {
        final gatewayKey = await getGatewayKey(unixTime);
        header['gateway_key'] = gatewayKey;
        header['unixtime'] = unixTime.toString();
      } else if (MicropackInit.appFlavor == Flavor.staging) {
        final gatewayKey = await getGatewayKey(unixTime);
        header['gateway_key'] = gatewayKey;
        header['unixtime'] = unixTime.toString();
      } else {
        header['gateway_key'] = MicropackInit.apiDevKey;
        header['unixtime'] = unixTime.toString();
      }

      if (_dio == null) {
        _dio = Dio(BaseOptions(
          baseUrl: MicropackConfig.baseUrl,
          headers: header,
          connectTimeout: Duration(seconds: MicropackInit.requestTimeout),
          receiveTimeout: Duration(seconds: MicropackInit.requestTimeout),
          sendTimeout: Duration(seconds: MicropackInit.requestTimeout),
        ));
        initInterceptors();
      }

      if (method == Method.POST) {
        response = await _dio!.post(url, data: formData ?? parameters);
      } else if (method == Method.PUT) {
        response = await _dio!.put(url, data: formData ?? parameters);
      } else if (method == Method.DELETE) {
        response = await _dio!.delete(url, queryParameters: params);
      } else if (method == Method.PATCH) {
        response = await _dio!.patch(url);
      } else {
        response = await _dio!.get(url, queryParameters: params);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        var result = {
          "success": response.data["success"],
          "statusCode": response.statusCode,
          "data": response.data["data"],
          "message": response.data["message"],
        };
        return result;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error');
      } else {
        throw Exception("Something does wen't wrong");
      }
    } on SocketException catch (e) {
      logSys(e.toString());
      throw Exception('Not Internet Connection');
    } on FormatException catch (e) {
      logSys(e.toString());
      throw Exception('Bad response format');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        final response = e.response;
        try {
          if (response != null) {
            var result = {
              "success": response.data["success"],
              "statusCode": e.response?.statusCode,
              "data": response.data["data"],
              "message": response.data["message"],
            };
            return result;
          }
        } catch (e) {
          throw Exception('Internal Error : $e');
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Request timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Connection Error');
      } else if (e.error is SocketException) {
        throw Exception('No Internet Connection!');
      }
    } catch (e) {
      rethrow;
    }
  }
}
