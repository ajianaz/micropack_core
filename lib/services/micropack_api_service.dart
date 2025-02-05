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
  Dio? _dio;

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

  void initInterceptors() {
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

  Future<Map<String, dynamic>> getHeader({
    Map<String, dynamic>? headers,
    required bool isToken,
    bool useGatewayKey = true, // Option for dynamic gateway_key
  }) async {
    final header = <String, dynamic>{'Content-Type': 'application/json'};

    if (headers != null) {
      header.addAll(headers);
    }

    if (isToken) {
      var token = await MicropackStorage.read(key: MicropackInit.boxToken);
      header['Authorization'] = 'Bearer $token';
    }

    // Add gateway_key dynamically based on the option
    if (useGatewayKey) {
      final unixTime = DateTime.now().millisecondsSinceEpoch;
      final gatewayKey = await getGatewayKey(unixTime);
      header['gateway_key'] = gatewayKey;
      header['unixtime'] = unixTime.toString();
    }

    return header;
  }

  Future<String> getGatewayKey(int unixtime) async {
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

  Future<dynamic> request({
    required String url,
    required Method method,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? parameters,
    FormData? formData,
    bool isToken = true,
    bool isCustomResponse = false,
    bool useGatewayKey = true, // Option for gateway_key
  }) async {
    Response response;

    final params = parameters ?? <String, dynamic>{};

    final header = await getHeader(
        headers: headers, isToken: isToken, useGatewayKey: useGatewayKey);

    try {
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
        throw Exception("Something went wrong");
      }
    } on SocketException catch (e) {
      logSys(e.toString());
      throw Exception('No Internet Connection');
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

  Future<void> getStreamData({
    required String url,
    Map<String, dynamic>? headers,
    bool isToken = false,
    bool useGatewayKey = false,
  }) async {
    final header = await getHeader(headers: headers, isToken: isToken);

    // Add gateway key dan unix time if needed
    if (useGatewayKey) {
      final unixTime = DateTime.now().millisecondsSinceEpoch;
      header['gateway_key'] = await getGatewayKey(unixTime);
      header['unixtime'] = unixTime.toString();
    }

    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: header,
          responseType: ResponseType.stream,
        ),
      );

      // Mendapatkan data stream
      final stream = response.data.stream;

      // Proses stream data secara langsung
      stream.listen(
        (List<int> data) {
          // Tangani setiap potongan data yang datang dari stream
          logSys(
              'Received data: ${String.fromCharCodes(data)}'); // Misalnya mencetak hasil stream
        },
        onDone: () {
          logSys('Stream completed');
        },
        onError: (error) {
          logSys('Error: $error');
        },
      );
    } catch (e) {
      logSys('Error while getting stream data: $e');
      throw Exception('Error fetching stream data');
    }
  }

  Future<void> downloadFileStream({
    required String url,
    required String savePath,
    Map<String, dynamic>? headers,
    bool isToken = true,
    bool useGatewayKey = true,
  }) async {
    final header = await getHeader(headers: headers, isToken: isToken);

    // Menambahkan gateway key dan unix time jika diperlukan
    if (useGatewayKey) {
      final unixTime = DateTime.now().millisecondsSinceEpoch;
      header['gateway_key'] = await getGatewayKey(unixTime);
      header['unixtime'] = unixTime.toString();
    }

    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: header,
          responseType: ResponseType.stream,
        ),
      );

      final file = File(savePath);
      final sink = file.openWrite();
      await response.data.stream.listen(
        (List<int> data) {
          sink.add(data);
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          logSys('File downloaded to $savePath');
        },
        onError: (error) {
          logSys('Error downloading file stream: $error');
        },
      );
    } catch (e) {
      logSys('Error downloading file: $e');
      throw Exception('Error downloading file');
    }
  }

  Future<Map<String, dynamic>> uploadFile({
    required String url,
    required String filePath,
    required String filename,
    Map<String, dynamic>? headers,
    bool isToken = true,
    bool useGatewayKey = true,
  }) async {
    final header = await getHeader(headers: headers, isToken: isToken);

    // Menambahkan gateway key dan unix time jika diperlukan
    if (useGatewayKey) {
      final unixTime = DateTime.now().millisecondsSinceEpoch;
      header['gateway_key'] = await getGatewayKey(unixTime);
      header['unixtime'] = unixTime.toString();
    }

    try {
      final dio = Dio();
      final file = await MultipartFile.fromFile(filePath, filename: filename);
      final formData = FormData.fromMap({
        'file': file,
      });

      final response = await dio.post(
        url,
        data: formData,
        options: Options(headers: header),
        onSendProgress: (int sent, int total) {
          if (total != -1) {
            final progress = (sent / total * 100).toStringAsFixed(2);
            logSys('Uploading: $progress%');
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var result = {
          "success": response.data["success"],
          "statusCode": response.statusCode,
          "data": response.data["data"],
          "message": response.data["message"],
        };
        return result;
      } else {
        throw Exception('Error during file upload');
      }
    } catch (e) {
      logSys('Error uploading file: $e');
      throw Exception('Error uploading file');
    }
  }

  Future<void> downloadFile({
    required String url,
    required String savePath,
    Map<String, dynamic>? headers,
    bool isToken = true,
    bool useGatewayKey = true,
  }) async {
    final header = await getHeader(headers: headers, isToken: isToken);

    // Menambahkan gateway key dan unix time jika diperlukan
    if (useGatewayKey) {
      final unixTime = DateTime.now().millisecondsSinceEpoch;
      header['gateway_key'] = await getGatewayKey(unixTime);
      header['unixtime'] = unixTime.toString();
    }

    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: header,
          responseType: ResponseType.stream,
        ),
      );

      final file = File(savePath);
      final sink = file.openWrite();
      await response.data.stream.pipe(sink);
      await sink.flush();
      await sink.close();
      logSys('File downloaded to $savePath');
    } catch (e) {
      logSys('Error downloading file: $e');
      throw Exception('Error downloading file');
    }
  }
}
